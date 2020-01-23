
# builds pa_schemer.cmo

echo ocamlrun ../boot/camlp5 -nolib -I ../boot pa_r.cmo pa_rp.cmo pa_extend.cmo q_MLast.cmo pr_dump.cmo -mode S -o pa_r5rsr.ppo pa_r5rsr.ml
ocamlrun ../boot/camlp5 -nolib -I ../boot pa_r.cmo pa_rp.cmo pa_extend.cmo q_MLast.cmo pr_dump.cmo -mode S -o pa_r5rsr.ppo pa_r5rsr.ml

echo ocamlc.opt -warn-error A -I ../main -I ../boot -I ../lib -c -impl pa_r5rsr.ppo
ocamlc.opt -warn-error A -I ../main -I ../boot -I ../lib -c -impl pa_r5rsr.ppo

echo rm -f pa_r5rsr.ppo
rm -f pa_r5rsr.ppo
