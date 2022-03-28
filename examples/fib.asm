loop:   lda :x
        add :y
        sta :z
        lda :y
        sta :x
        lda :z
        sta :y
        jc :exit
        lda :z
        out
        jmp :loop
exit:   hlt
x:      0
y:      1
z:      0
