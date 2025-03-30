# using StaticArrays
Ci serve usare questo pacchetto per avere matrici a dimensione fissata piuttosto che la semplice Matrix?

# try-catch into function Parameters(ARGS)
il try-catch va messo solo nel main ma come faccio a toglierli dalla funzione parameters? non ho trovato un modo diverso per il parse()

# write/read HDR-LDR into io.jl
metterei tutte le funzioni di scrittura e lettura nello stesso file io.jl al posto che colors.jl

# attenzione a open
per un'apertura sicura credo vada usato il blocco:
open(filename, "quellochevoglio") do io
    funzione(io, .....)
end

# read_pfm_file
creare una funzione per leggere da file pfm
aggiustata la funzione commentata

# parameters
non ho messo la lumi nei parameters, secondo me perché la lumi può servire solo per i test. (normalize_image) nel caso aggiungo in un secondo momento

# specificare il formato LDR (.jpg, .png ...)
importante adattare Parameters e le altre funzioni.

# ho cambiato write_color_ldr
perchè mi dava errore nel Int(c.r^1/gamma) VERIFICARE!!
ERROR: LoadError: type InexactError has no field msg
Stacktrace:
 [1] getproperty(x::InexactError, f::Symbol)
   @ Base .\Base.jl:49
 [2] main()
   @ Main C:\Users\stefa\Calcolo_numerico\RayTracer\RayTracer:40
 [3] top-level scope
   @ C:\Users\stefa\Calcolo_numerico\RayTracer\RayTracer:45
in expression starting at C:\Users\stefa\Calcolo_numerico\RayTracer\RayTracer:45

caused by: InexactError: Int64(3.677814812399447)
Stacktrace:
 [1] Int64
   @ .\float.jl:994 [inlined]
 [2] write_ldr_image(image::HdrImage, filename::String; gamma::Float64)
   @ RayTracer C:\Users\stefa\Calcolo_numerico\RayTracer\src\colors.jl:218
 [3] write_ldr_image
   @ C:\Users\stefa\Calcolo_numerico\RayTracer\src\colors.jl:214 [inlined]
 [4] main()
   @ Main C:\Users\stefa\Calcolo_numerico\RayTracer\RayTracer:29
 [5] top-level scope
   @ C:\Users\stefa\Calcolo_numerico\RayTracer\RayTracer:45
PS C:\Users\stefa\Calcolo_numerico\RayTracer> 

# valori non validi :|
problema che Image.save vuole roba in intervallo diverso a quanto pare, non capisco c'è qualcosa che non va

┌ Warning: Mapping to the storage type failed; perhaps your data had out-of-range values?
│ Try `map(clamp01nan, img)` to clamp values to a valid range.
└ @ ImageMagick C:\Users\stefa\.julia\packages\ImageMagick\iwBdP\src\ImageMagick.jl:180