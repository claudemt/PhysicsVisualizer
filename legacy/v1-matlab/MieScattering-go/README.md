# Program for rendering Mie Scattering by spherical dielectric sphere.

## Generating data 
```
go run . --n-re 1.33 --n-im 0.2 --r-min 1.25 --r-max 1.28 
```
## Rendering .png of generated data (video optional)
```
cd render
go run . --heatmap-file ..\..\heatmaps\wikipedia.png --params ..\data\params.json --gamma 0.5 --video true
```
