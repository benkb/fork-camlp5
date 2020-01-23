ocamlrun ../boot/camlp5 -nolib -I ../boot pa_r.cmo pa_rp.cmo pa_extend.cmo q_MLast.cmo pr_dump.cmo -mode S -o pa_schemer.ppo pa_schemer.ml

ocamlc.opt -warn-error A -I ../main -I ../boot -I ../lib -c -impl pa_schemer.ppo

rm -f pa_schemer.ppo

/Applications/Xcode.app/Contents/Developer/usr/bin/make --no-print-directory -f Makefile.withnew pa_scheme.cmo

ocamlrun ../main/camlp5 -nolib -I ../meta -I ../etc ./pa_schemer.cmo pa_extend.cmo q_MLast.cmo pr_dump.cmo -mode S -o pa_scheme.ppo pa_scheme.ml

ocamlc.opt -warn-error A -I ../main -I ../meta -I ../lib -c -impl pa_scheme.ppo

rm -f pa_scheme.ppo

ocamlrun ../boot/camlp5 -nolib -I ../boot ./pa_schemer.cmo pa_extend.cmo q_MLast.cmo pr_dump.cmo -mode S -o pa_r5rsr.ppo pa_r5rsr.ml
