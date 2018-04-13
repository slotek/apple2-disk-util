@echo off

for %%f in (blank.dsk.gz bsave.dsk.gz bsave2.dsk.gz src.dsk.gz) do (
    if exist %%f (
        gzip -d %%f
    )
)
del *.txt

set GLI_DEBUG=true
set RUBYLIB=..\lib

copy blank.dsk dest.dsk
ruby ..\bin\a2 cp STARMAZE src.dsk dest.dsk > out.txt
diff bsave.dsk dest.dsk > diff.txt

copy dest.dsk dest2.dsk
ruby  ..\bin\a2 cp -d STARMAZE2 STARMAZE src.dsk dest2.dsk > out2.txt
diff bsave2.dsk dest2.dsk > diff2.txt

cat diff*.txt
