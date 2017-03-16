for f in blank.dsk.gz bsave.dsk.gz bsave2.dsk.gz src.dsk.gz; do
    if [[ -f $f ]]; then
        gzip -d $f;
    fi
done
rm *.txt

cp blank.dsk dest.dsk
GLI_DEBUG=true ../a2 cp STARMAZE src.dsk dest.dsk > out.txt
diff bsave.dsk dest.dsk > diff.txt

cp dest.dsk dest2.dsk
GLI_DEBUG=true ../a2 cp -d STARMAZE2 STARMAZE src.dsk dest2.dsk > out2.txt
diff bsave2.dsk dest2.dsk > diff2.txt

cat diff*.txt
