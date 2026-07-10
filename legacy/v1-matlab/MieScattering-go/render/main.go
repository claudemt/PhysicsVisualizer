package main

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"math"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/llgcode/draw2d"
	"github.com/llgcode/draw2d/draw2dimg"

	"github.com/euphoricrhino/jackson-em-notes/go/pkg/heatmap"
)

const (
	// fixed (not configurable)
	width  = 800
	height = 800

	// fixed output dir: root/data
	outDir = "../data"

	// video settings (as requested)
	videoFramerate = "20.75"
	videoProfile   = "high"
	videoCRF       = "10"
	videoPixFmt    = "yuv420p"
)

var (
	heatmapFile = flag.String("heatmap-file", "", "heatmap file")
	paramsFile  = flag.String("params", "../data/params.json", "params json file (auto config)")
	gamma       = flag.Float64("gamma", 1.0, "gamma correction")

	// new
	video = flag.Bool("video", false, "if true, generate mp4 videos with ffmpeg (no numbered PNGs kept)")
)

type Params struct {
	Width   int     `json:"width"`
	Height  int     `json:"height"`
	Count   int     `json:"count"`
	RStart  float64 `json:"r_start"`
	RInc    float64 `json:"r_inc"`
	N       float64 `json:"n"`
	NImg    float64 `json:"n_img"`
	OutDir  string  `json:"out_dir"`
	PrefixT string  `json:"prefix_total"`
	PrefixS string  `json:"prefix_scattered"`
}

func main() {
	flag.Parse()

	if *heatmapFile == "" {
		panic("heatmap-file is required")
	}

	p := mustLoadParams(*paramsFile)

	// enforce fixed size
	if p.Width != width || p.Height != height {
		panic(fmt.Sprintf("params.json width/height = %dx%d, but render is fixed to %dx%d. Regenerate data with 800x800.",
			p.Width, p.Height, width, height))
	}

	if err := os.MkdirAll(outDir, 0755); err != nil {
		panic(fmt.Sprintf("failed to create output dir '%v': %v", outDir, err))
	}

	hm, err := heatmap.Load(*heatmapFile, *gamma)
	if err != nil {
		panic(fmt.Sprintf("failed to load heatmap: %v", err))
	}

	// If video is requested, create a temp directory under outDir for numbered PNGs.
	// It will be removed automatically at the end.
	numberedDir := ""
	if *video {
		tmp, err := os.MkdirTemp(outDir, ".tmp-video-")
		if err != nil {
			panic(fmt.Sprintf("failed to create temp dir under '%s': %v", outDir, err))
		}
		numberedDir = tmp
		defer func() {
			_ = os.RemoveAll(numberedDir) // delete numbered PNG cache
		}()
	}

	// Render both prefixes
	prefixes := []string{"mie-scattered", "mie-total"}
	for _, prefix := range prefixes {
		fmt.Printf("Rendering %s... (%d frame(s))\n", prefix, p.Count)
		renderSeries(prefix, p, hm, numberedDir)
	}

	fmt.Printf("Done. Parameter-named PNGs are in %s\n", outDir)

	// If requested, stitch into videos with ffmpeg using numbered PNGs in temp dir
	if *video {
		fmt.Println("Creating videos with ffmpeg...")
		absOutDir, err := filepath.Abs(outDir)
		if err != nil {
			panic(fmt.Sprintf("failed to resolve absolute path for outDir: %v", err))
		}
		mustMakeVideo(numberedDir, absOutDir, "mie-scattered", p)
		mustMakeVideo(numberedDir, absOutDir, "mie-total", p)
		fmt.Printf("Done. Videos saved in %s\n", outDir)
	}
}

func mustLoadParams(path string) Params {
	b, err := os.ReadFile(path)
	if err != nil {
		panic(fmt.Sprintf("failed to read params file: %v", err))
	}
	var p Params
	if err := json.Unmarshal(b, &p); err != nil {
		panic(fmt.Sprintf("failed to parse params file: %v", err))
	}
	// sensible defaults if fields missing
	if p.PrefixS == "" {
		p.PrefixS = "mie-scattered"
	}
	if p.PrefixT == "" {
		p.PrefixT = "mie-total"
	}
	return p
}

func renderSeries(prefix string, p Params, hm []color.Color, numberedDir string) {
	dataPrefix := filepath.Join(outDir, prefix) // data files live in ../data

	// Pass 1: global min/max across all frames
	maxV, minV := math.NaN(), math.NaN()
	for i := 0; i < p.Count; i++ {
		data := loadData(fmt.Sprintf("%v-%03v.data", dataPrefix, i))
		for _, v := range data {
			if math.IsNaN(maxV) || maxV < v {
				maxV = v
			}
			if math.IsNaN(minV) || minV > v {
				minV = v
			}
		}
	}

	spread := maxV - minV
	if !(spread > 0) {
		panic(fmt.Sprintf("invalid spread for %s: max=%v min=%v", prefix, maxV, minV))
	}

	// Pass 2: normalize and render
	for frame := 0; frame < p.Count; frame++ {
		data := loadData(fmt.Sprintf("%v-%03v.data", dataPrefix, frame))
		for i := range data {
			data[i] = (data[i] - minV) / spread
		}
		savePNG(data, hm, frame, prefix, p, numberedDir)
	}
}

func formatN(p Params) string {
	if p.NImg == 0 {
		return fmt.Sprintf("%.6g+0i", p.N)
	}
	// %+.6g makes sure we get + / - sign for imag part
	return fmt.Sprintf("%.6g%+.6gi", p.N, p.NImg)
}

func formatRoverLambda(p Params, frame int) string {
	r := p.RStart + float64(frame)*p.RInc
	return fmt.Sprintf("%.2f", r) // 0.01 step -> 2 decimals is safe
}

func postEdit(img draw.Image, frame int, prefix string, p Params) {
	gc := draw2dimg.NewGraphicContext(img)
	gc.SetLineWidth(1)

	// Windows font
	draw2d.SetFontFolder("C:\\Windows\\Fonts")
	draw2d.SetFontNamer(func(_ draw2d.FontData) string { return "consola.ttf" })

	nStr := formatN(p)
	text := fmt.Sprintf("%s | n=%s, R=%.2fλ", prefix, nStr, p.RStart+float64(frame)*p.RInc)

	textColor := color.RGBA{0, 0xcc, 0xcc, 0xff}
	gc.SetFillColor(textColor)
	gc.SetStrokeColor(textColor)
	gc.SetDPI(288)
	gc.SetFontSize(3.5)
	gc.FillStringAt(text, 20.0, 20.0)
}

func savePNG(data []float64, hm []color.Color, frame int, prefix string, p Params, numberedDir string) {
	img := image.NewRGBA(image.Rect(0, 0, width, height))
	for x := 0; x < width; x++ {
		for y := 0; y < height; y++ {
			pixel := data[y*width+x]
			// clamp for safety
			if pixel < 0 {
				pixel = 0
			} else if pixel > 1 {
				pixel = 1
			}
			pos := int(pixel * float64(len(hm)-1))
			r, g, b, a := hm[pos].RGBA()
			img.SetRGBA64(x, y, color.RGBA64{R: uint16(r), G: uint16(g), B: uint16(b), A: uint16(a)})
		}
	}

	postEdit(img, frame, prefix, p)

	// 1) Always write the parameter-named PNG into ../data
	nPart := formatN(p)
	rPart := formatRoverLambda(p, frame)
	pretty := filepath.Join(outDir, fmt.Sprintf("%s-%s-%s.png", prefix, nPart, rPart))
	writePNG(pretty, img)

	// 2) If video requested, also write numbered PNG into temp cache dir (NOT outDir)
	if numberedDir != "" {
		numbered := filepath.Join(numberedDir, fmt.Sprintf("%s-%03d.png", prefix, frame))
		writePNG(numbered, img)
	}
}

func writePNG(filename string, img image.Image) {
	out, err := os.Create(filename)
	if err != nil {
		panic(fmt.Sprintf("failed to create output file '%v': %v", filename, err))
	}
	defer out.Close()

	if err := png.Encode(out, img); err != nil {
		panic(fmt.Sprintf("failed to encode to PNG: %v", err))
	}
}

func loadData(filename string) []float64 {
	f, err := os.Open(filename)
	if err != nil {
		panic(fmt.Sprintf("failed to open file: %v", err))
	}
	defer f.Close()

	data := make([]float64, width*height)
	for i := range data {
		if err := binary.Read(f, binary.LittleEndian, &data[i]); err != nil {
			panic(fmt.Sprintf("failed to read data '%s': %v", filename, err))
		}
	}
	return data
}

func mustMakeVideo(numberedDir string, absOutDir string, prefix string, p Params) {
	// Runs (in numberedDir):
	// ffmpeg -framerate 20.75 -i mie-scattered-%03d.png -c:v libx264 -profile:v high -crf 10 -pix_fmt yuv420p -y <absOutDir>/mie-scattered.mp4
	nStr := formatN(p)
	rMin := fmt.Sprintf("%.2f", p.RStart)
	rMax := fmt.Sprintf("%.2f", p.RStart+float64(p.Count-1)*p.RInc)
	rStep := fmt.Sprintf("%.2f", p.RInc)

	// mie-scattered-1.33+0.2i-1.25&1.34&0.01.mp4
	videoName := fmt.Sprintf("%s-%s-%s&%s&%s.mp4", prefix, nStr, rMin, rMax, rStep)
	outPath := filepath.Join(absOutDir, videoName)

	args := []string{
		"-framerate", videoFramerate,
		"-i", fmt.Sprintf("%s-%%03d.png", prefix),
		"-c:v", "libx264",
		"-profile:v", videoProfile,
		"-crf", videoCRF,
		"-pix_fmt", videoPixFmt,
		"-y", outPath,
	}

	cmd := exec.Command("ffmpeg", args...)
	cmd.Dir = numberedDir

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		panic(fmt.Sprintf("ffmpeg failed for %s: %v\nstdout:\n%s\nstderr:\n%s",
			prefix, err, stdout.String(), stderr.String()))
	}
}
