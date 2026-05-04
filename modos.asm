; lab6_modos.asm — Demostración de modos de direccionamiento x86
; Compilar: nasm -f bin lab6_modos.asm -o lab6_modos.com
org 100h
; ── Datos de prueba
jmp inicio
; Array de 5 enteros de 16 bits
array dw 10, 20, 30, 40, 50
; Registro de estudiante: nota1(16b) + nota2(16b) + promedio(16b)
nota1 dw 85
nota2 dw 73
promedio dw 0
; Variable simple para direccionamiento directo
var_x dw 0FFFFh
; Tabla de bytes para XLAT (opcional)
tabla_hex db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,41h,42h,43h,44h,45h,46h
inicio:
; ── MODO 1: INMEDIATO
; El operando es un valor constante dentro de la instrucción
; Desensamblar con DEBUG→U revela el valor 0064h en el opcode
 MOV ax, 100 ; AX = 100 — inmediato decimal
 MOV bx, 0A5h ; BX = 0xA5 — inmediato hex
 ADD cx, 55 ; CX += 55 — inmediato en operación aritmética
 AND dx, 00FFh ; DX AND máscara inmediata
; Verificación con DEBUG:
; Comando U 100 (desensamblar desde offset 0x100)
; Observar: "MOV AX,0064" — el 64h (100) está en el opcode
; No se genera tráfico de bus a memoria de datos
; ── MODO 2: DIRECTO
; La dirección del operando está fija en la instrucción
 MOV ax, [var_x] ; AX ← mem[dir_var_x] = 0FFFFh
 MOV bx, [array] ; BX ← mem[dir_array] = 10 (primer elemento)
 MOV cx, [nota1] ; CX ← mem[dir_nota1] = 85
 ; Modificar variable directamente en memoria
 MOV word [var_x], 0 ; mem[dir_var_x] = 0 (escribe en memoria)
; Verificación con DEBUG:
; Desensamblar con U: "MOV AX,[01XX]" — la dirección se ve en el opcode
; Comando D DS:dir_array — mostrar el contenido del array en memoria
; Observar 0A00h, 1400h, 1E00h... (little-endian: 10=0x000A → 0A 00)
; ── MODO 3: INDIRECTO POR REGISTRO
; El registro contiene la dirección — el puntero puede cambiar en runtime
 ; Puntero a nota1
 MOV si, nota1 ; SI = dirección de nota1 (no su valor)
 MOV ax, [si] ; AX ← mem[SI] = 85
 ; Puntero a nota2
 MOV si, nota2 ; SI = dirección de nota2
 MOV bx, [si] ; BX ← mem[SI] = 73
 ; Calcular promedio usando punteros
 ADD ax, bx ; AX = 85 + 73 = 158
 SHR ax, 1 ; AX = 158 >> 1 = 79 (división por 2)
 MOV si, promedio ; SI = dirección de promedio
 MOV [si], ax ; mem[SI] = 79 (guarda promedio vía puntero)
; Verificación con DEBUG:
; T (traza) paso a paso — observar cómo SI cambia entre instrucciones
; D DS:dir_promedio — verificar que el valor 79 (0x004F) fue escrito
; ── MODO 4: INDEXADO (BASE + ÍNDICE + DESPLAZAMIENTO) ────────────────────
; Dirección efectiva = Base + Índice + Desplazamiento
 ; Acceso a elemento específico del array: array[2] = 30
 MOV bx, array ; BX = dirección base del array
 MOV si, 4 ; SI = índice * sizeof(word) = 2 * 2 = 4
 MOV ax, [bx + si] ; AX ← mem[BX+SI] = array[2] = 30
 ; Suma acumulada en orden INVERSO (array[4] -> array[0])
 XOR ax, ax        ; AX = 0 (acumulador)
 MOV bx, array     ; BX = dirección base
 MOV cx, 5         ; CX = número de elementos
 MOV si, 8         ; SI = 4 * 2 = offset del último elemento
 bucle_inverso:
    ADD ax, [bx + si]   ; AX += array[si/2]
    SUB si, 2           ; retroceder índice 2 bytes
    LOOP bucle_inverso
    ; AX = 50+40+30+20+10 = 150
 ; AX = 10+20+30+40+50 = 150
 ; Acceso a campo de struct con desplazamiento fijo
 MOV bx, nota1 ; BX = base del "struct" (nota1, nota2, promedio)
 MOV ax, [bx] ; AX = nota1 = 85 (offset 0)
 MOV cx, [bx + 2] ; CX = nota2 = 73 (offset 2)
 MOV dx, [bx + 4] ; DX = promedio = 79 (offset 4)
 INT 20h ; retornar a DOS