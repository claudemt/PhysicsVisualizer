package main

import (
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
)

const (
	// fixed (not configurable)
	width  = 800
	height = 800

	lambda = 0.2
	k      = 2.0 * math.Pi / lambda

	// fixed step in R/lambda
	rStepOverLambda = 0.01

	// fixed output dir
	dataDir = "./data"
)

var (
	// Only user inputs
	nRe       = flag.Float64("n-re", 1.33, "Refractive index (real part)")
	nIm       = flag.Float64("n-im", 0.0, "Refractive index (imaginary part)")
	rMinOverL = flag.Float64("r-min", 0.25, "Min radius in units of lambda (R/lambda)")
	rMaxOverL = flag.Float64("r-max", 4.00, "Max radius in units of lambda (R/lambda)")

	// Still useful to expose physics accuracy knob
	maxL = flag.Int("max-l", 42, "max l value")

	mu = flag.Float64("mu", 1.0, "Permeability")
)

type Params struct {
	Width   int     `json:"width"`
	Height  int     `json:"height"`
	Count   int     `json:"count"`
	RStart  float64 `json:"r_start"` // in R/lambda
	RInc    float64 `json:"r_inc"`   // in R/lambda
	N       float64 `json:"n"`
	NImg    float64 `json:"n_img"`
	MaxL    int     `json:"max_l"`
	Lambda  float64 `json:"lambda"`
	OutDir  string  `json:"out_dir"`
	PrefixT string  `json:"prefix_total"`     // "mie-total"
	PrefixS string  `json:"prefix_scattered"` // "mie-scattered"
}

func ensureDir(path string) {
	if err := os.MkdirAll(path, 0755); err != nil {
		panic(fmt.Sprintf("failed to create dir '%v': %v", path, err))
	}
}

func writeParams(outDir string, p Params) {
	b, err := json.MarshalIndent(p, "", "  ")
	if err != nil {
		panic(fmt.Sprintf("failed to marshal params: %v", err))
	}
	filename := filepath.Join(outDir, "params.json")
	if err := os.WriteFile(filename, b, 0644); err != nil {
		panic(fmt.Sprintf("failed to write params file '%v': %v", filename, err))
	}
}

func main() {
	flag.Parse()

	if *rMinOverL > *rMaxOverL {
		panic(fmt.Sprintf("invalid range: r-min(%.6g) > r-max(%.6g)", *rMinOverL, *rMaxOverL))
	}

	ensureDir(dataDir)

	// Count frames: include both ends; if min==max => 1 frame
	cnt := countFrames(*rMinOverL, *rMaxOverL, rStepOverLambda)

	// Write params.json into ./data
	writeParams(dataDir, Params{
		Width:   width,
		Height:  height,
		Count:   cnt,
		RStart:  *rMinOverL,
		RInc:    rStepOverLambda,
		N:       *nRe,
		NImg:    *nIm,
		MaxL:    *maxL,
		Lambda:  lambda,
		OutDir:  dataDir,
		PrefixT: "mie-total",
		PrefixS: "mie-scattered",
	})

	// Generate frames
	frame := 0
	for rOverL := *rMinOverL; rOverL <= *rMaxOverL+1e-12; rOverL += rStepOverLambda {
		rad := rOverL * lambda
		totalField, scatteredField := computeOneFrame(rad, *nRe, *nIm, *mu, *maxL)
		saveFrame(totalField, filepath.Join(dataDir, fmt.Sprintf("mie-total-%03v.data", frame)))
		saveFrame(scatteredField, filepath.Join(dataDir, fmt.Sprintf("mie-scattered-%03v.data", frame)))
		frame++
		if frame >= cnt {
			break // avoid floating rounding drift
		}
	}

	fmt.Printf("Done. Generated %d frame(s) into %s\n", cnt, dataDir)
	fmt.Printf("Params: %s\n", filepath.Join(dataDir, "params.json"))
}

func countFrames(rMin, rMax, step float64) int {
	if math.Abs(rMax-rMin) < 1e-15 {
		return 1
	}
	return int(math.Floor((rMax-rMin)/step+0.5)) + 1
}

func saveFrame(data []float64, filename string) {
	f, err := os.Create(filename)
	if err != nil {
		panic(fmt.Sprintf("failed to create output file '%v': %v", filename, err))
	}
	defer f.Close()
	for _, v := range data {
		_ = binary.Write(f, binary.LittleEndian, v)
	}
}

func computeOneFrame(rad float64, nre, nim, mu float64, maxL int) ([]float64, []float64) {
	workers := 2 * runtime.NumCPU()
	var wg sync.WaitGroup
	wg.Add(workers)

	totalField := make([]float64, width*height)
	scatteredField := make([]float64, width*height)
	cnt := int32(0)

	for w := 0; w < workers; w++ {
		go func(i int) {
			defer wg.Done()
			for x := width / 2; x < width; x++ {
				if x%workers != i {
					continue
				}
				for y := 0; y < height; y++ {
					totalVal, scatteredVal := mieField(x, y, rad, nre, nim, mu, maxL)
					totalField[y*width+x] = totalVal
					scatteredField[y*width+x] = scatteredVal
					// Symmetrically fill the other half.
					totalField[y*width+(width-1-x)] = totalVal
					scatteredField[y*width+(width-1-x)] = scatteredVal
					atomic.AddInt32(&cnt, 2)
				}
			}
		}(w)
	}

	total := width * height

	// Progress counter.
	counterDone := make(chan struct{})
	go func() {
		erase := strings.Repeat(" ", 80)
		nextMark := 1.0
		for {
			doneCnt := int(atomic.LoadInt32(&cnt))
			if doneCnt == total {
				fmt.Printf("\r%v\rR=%.2fλ rendering complete\n", erase, rad/lambda)
				close(counterDone)
				return
			}
			progress := float64(doneCnt) / float64(total) * 100.0
			if progress >= nextMark {
				fmt.Printf(
					"\r%v\rrendering for R=%.2fλ... %.2f%% done",
					erase,
					rad/lambda,
					progress,
				)
				nextMark = math.Ceil(progress)
			}
			runtime.Gosched()
		}
	}()

	wg.Wait()
	<-counterDone

	return totalField, scatteredField
}

func mieField(x, y int, rad float64, nre, nim, mu float64, maxL int) (float64, float64) {
	stepx, stepy := 2.0/float64(width), 2.0/float64(height)
	cx, cy := float64(width-1)/2, float64(height-1)/2

	fx, fy := stepx*(float64(x)-cx), stepy*(cy-float64(y))
	r := math.Sqrt(fx*fx + fy*fy)

	// guard the origin to avoid 0/0
	var st, ct float64
	if r < 1e-15 {
		st, ct = 0.0, 1.0
	} else {
		st, ct = math.Abs(fx/r), fy/r
	}

	// j_l(x), j_l'(x).
	z1 := func(t float64) ([]*bigComplex, []*bigComplex) {
		jval, jder := sphericalBessel1(maxL, t)
		zval := make([]*bigComplex, maxL+1)
		zder := make([]*bigComplex, maxL+1)
		for i := 0; i <= maxL; i++ {
			zval[i] = bigComplexFromBigFloat(jval[i])
			zder[i] = bigComplexFromBigFloat(jder[i])
		}
		return zval, zder
	}

	z1c := func(z complex128) ([]*bigComplex, []*bigComplex) {
		return sphericalBessel1C(maxL, z)
	}

	// h_l^1(x), h_l^1'(x).
	z3 := func(t float64) ([]*bigComplex, []*bigComplex) {
		jval, jder := sphericalBessel1(maxL, t)
		yval, yder := sphericalBessel2(maxL, t)
		zval := make([]*bigComplex, maxL+1)
		zder := make([]*bigComplex, maxL+1)
		for i := 0; i <= maxL; i++ {
			zval[i] = newBigComplex(jval[i], yval[i])
			zder[i] = newBigComplex(jder[i], yder[i])
		}
		return zval, zder
	}

	useComplex := nim != 0

	ka := k * rad

	var (
		cn      *bigComplex
		cnka    *bigComplex
		intN    []*bigComplex
		intNder []*bigComplex
	)
	if useComplex {
		cn = bigComplexFromComplex128(complex(nre, nim))
		nka := complex(nre, nim) * complex(ka, 0.0)
		intN, intNder = z1c(nka)
		cnka = bigComplexFromComplex128(nka)
	} else {
		cn = bigComplexFromFloat64(nre)
		intN, intNder = z1(nre * ka)
		cnka = bigComplexFromFloat64(nre * ka)
	}
	cka := bigComplexFromFloat64(ka)
	intJ, intJder := z1(ka)
	intH, intHder := z3(ka)
	for i := 1; i <= maxL; i++ {
		intJder[i] = intJder[i].mul(cka)
		intJder[i] = intJder[i].add(intJ[i])

		intHder[i] = intHder[i].mul(cka)
		intHder[i] = intHder[i].add(intH[i])

		intNder[i] = intNder[i].mul(cnka)
		intNder[i] = intNder[i].add(intN[i])
	}

	cmu := bigComplexFromFloat64(mu)

	if r < rad {
		// Internal field.
		alpha := func(l int) *bigComplex {
			v := intJ[l].mul(intHder[l])
			v = v.sub(intJder[l].mul(intH[l]))
			v = v.mul(cmu)
			u := cmu.mul(intHder[l]).mul(intN[l])
			u = u.sub(intH[l].mul(intNder[l]))
			return v.quo(u)
		}
		beta := func(l int) *bigComplex {
			v := intJder[l].mul(intH[l])
			v = v.sub(intJ[l].mul(intHder[l]))
			v = v.mul(cmu).mul(cn)
			u := cmu.mul(intH[l]).mul(intNder[l])
			u = u.sub(cn.mul(cn).mul(intHder[l]).mul(intN[l]))
			return v.quo(u)
		}
		cnkr := complex(nre, nim) * complex(k*r, 0.0)
		intAmp := multipoleExpansion(
			st,
			ct,
			cnkr,
			alpha,
			beta,
			func(arg complex128) ([]*bigComplex, []*bigComplex) {
				if useComplex {
					return z1c(arg)
				}
				return z1(real(arg))
			},
			maxL,
		)
		return intAmp * intAmp, 0
	}

	// Scattered field coefficients.
	alpha := func(l int) *bigComplex {
		v := intJ[l].mul(intNder[l])
		v = v.sub(cmu.mul(intJder[l]).mul(intN[l]))
		u := cmu.mul(intHder[l]).mul(intN[l])
		u = u.sub(intH[l].mul(intNder[l]))
		return v.quo(u)
	}
	beta := func(l int) *bigComplex {
		v := cn.mul(cn).mul(intJder[l]).mul(intN[l])
		v = v.sub(cmu.mul(intJ[l]).mul(intNder[l]))
		u := cmu.mul(intH[l]).mul(intNder[l])
		u = u.sub(cn.mul(cn).mul(intHder[l]).mul(intN[l]))
		return v.quo(u)
	}

	// Scattered field plus incident field.
	scAmp := multipoleExpansion(
		st,
		ct,
		complex(k*r, 0),
		alpha,
		beta,
		func(arg complex128) ([]*bigComplex, []*bigComplex) {
			return z3(real(arg))
		},
		maxL,
	)
	incAmp := multipoleExpansion(
		st,
		ct,
		complex(k*r, 0),
		func(int) *bigComplex { return bigComplexFromInt(1) },
		func(int) *bigComplex { return bigComplexFromInt(1) },
		func(arg complex128) ([]*bigComplex, []*bigComplex) {
			return z1(real(arg))
		},
		maxL,
	)
	amp := scAmp + incAmp
	return amp * amp, scAmp * scAmp
}

func multipoleExpansion(
	st, ct float64,
	ckr complex128,
	alpha, beta func(int) *bigComplex,
	z func(complex128) ([]*bigComplex, []*bigComplex),
	maxL int,
) float64 {
	cst, cct := bigComplexFromFloat64(st), bigComplexFromFloat64(ct)

	pval, pder := legendre(maxL, ct)
	zval, zder := z(ckr)

	bigckr := bigComplexFromComplex128(ckr)
	// r-component.
	rcom := blankBigComplex()
	// theta-component.
	tcom := blankBigComplex()

	for l := 1; l <= maxL; l++ {
		alphal, betal := alpha(l), beta(l)
		coeff := iPow(l - 1).mul(bigComplexFromFloat64(float64(2*l+1) / float64(l*(l+1))))
		zlkrkr := zval[l].quo(bigckr)
		ll1 := bigComplexFromInt(l * (l + 1))
		rr := ll1.mul(betal).mul(zlkrkr)
		rr = rr.mul(cst)
		rr = rr.mul(pder[l])

		g := zlkrkr.add(zder[l])
		h := cct.mul(pder[l])
		h = h.sub(ll1.mul(pval[l]))

		tt := iPow(1).mul(alphal).mul(zval[l]).mul(pder[l])
		tt = tt.sub(betal.mul(g).mul(h))

		rcom = rcom.add(coeff.mul(rr))
		tcom = tcom.add(coeff.mul(tt))
	}

	// Extract the x-polarized field.
	rre, tre := rcom.re, tcom.re
	rre.Mul(rre, fromFloat64(st))
	tre.Mul(tre, fromFloat64(ct))

	rre.Add(rre, tre)
	f64, _ := rre.Float64()
	return f64
}
