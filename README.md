# lab6_modos — Modos de Direccionamiento x86 en NASM

**Autor:** Diego Ardila  
**Curso:** Arquitectura de Computadores — Ingeniería de Sistemas  
**Unidad:** 6 — Instrucciones y Direccionamiento  
**Actividad:** Post-Contenido 2  
**Año:** 2026

---

## Descripción

Este repositorio contiene el desarrollo del laboratorio de modos de direccionamiento en NASM para arquitectura x86. El programa (`lab6_modos.asm`) es un ejecutable `.COM` de DOS que demuestra de forma explícita y verificable cuatro modos de direccionamiento: **inmediato**, **directo**, **indirecto por registro** e **indexado con base, índice y desplazamiento**. Para cada modo se documenta la dirección efectiva calculada y el estado de los registros, verificado mediante la herramienta DEBUG en DOSBox.

> **Prerrequisito:** haber completado el Post-Contenido 1 (estructura de programa `.COM`, compilación y ejecución en DOSBox).

---

## Estructura del Repositorio

```
ardila-post2-u6/
├── lab6_modos.asm             # Código fuente en NASM
├── lab6_modos.com             # Binario compilado para DOS
├── README.md                  # Este archivo
└── capturas/
    ├── 01_dump_array.png      # Dump del array en DEBUG (D DS:100)
    ├── 02_traza_indirecto.png # Trazado paso a paso del modo indirecto
    └── 03_ax150_indexado.png  # AX=150 al finalizar el bucle indexado
```

---

## Requisitos del Entorno

| Software | Versión mínima |
|---|---|
| DOSBox | 0.74 |
| NASM (para DOS) | 2.11 |
| DEBUG.COM | Incluido en DOSBox o carpeta de herramientas |
| Editor de texto | Notepad++, VSCode + extensión ASM |

---

## Compilación y Ejecución

**Dentro de DOSBox:**

```dos
; 1. Montar la carpeta de trabajo
MOUNT C C:\Users\usuario\asm_lab6
C:

; 2. Compilar el programa
nasm -f bin lab6_modos.asm -o lab6_modos.com

; 3. Ejecutar directamente
lab6_modos.com

; 4. Abrir con DEBUG para inspección
debug lab6_modos.com
```

**Comandos DEBUG utilizados:**

| Comando | Descripción |
|---|---|
| `R` | Mostrar estado de todos los registros |
| `T` | Trazar una instrucción (paso a paso) |
| `U 100` | Desensamblar desde el offset 0x100 |
| `D DS:100` | Volcado hexadecimal del segmento de datos |
| `G` | Ejecutar hasta el final del programa |

---

## Estructura de Datos del Programa

El programa define en memoria las siguientes estructuras, accedidas con modos distintos para cada operación:

```nasm
array    dw 10, 20, 30, 40, 50   ; array de 5 enteros de 16 bits
nota1    dw 85                    ; campo 1 del "struct" estudiante
nota2    dw 73                    ; campo 2 del "struct" estudiante
promedio dw 0                     ; campo 3 — calculado en runtime
var_x    dw 0FFFFh                ; variable para modo directo
tabla_hex db 30h..46h             ; tabla de 16 bytes para XLAT
```

**Representación en memoria (little-endian), observable con `D DS:100`:**

| Offset | Valor hex | Valor decimal | Símbolo |
|---|---|---|---|
| +0x03 | `0A 00` | 10 | array[0] |
| +0x05 | `14 00` | 20 | array[1] |
| +0x07 | `1E 00` | 30 | array[2] |
| +0x09 | `28 00` | 40 | array[3] |
| +0x0B | `32 00` | 50 | array[4] |
| +0x0D | `55 00` | 85 | nota1 |
| +0x0F | `49 00` | 73 | nota2 |
| +0x11 | `00 00` | 0  | promedio (inicial) |

---

## Tabla Resumen de Modos de Direccionamiento

| Modo | Fórmula dirección efectiva | Instrucción NASM usada | Valor observado en DEBUG |
|---|---|---|---|
| **Inmediato** | El operando *es* el dato (embebido en el opcode) | `MOV ax, 100` | AX = 0x0064 (sin acceso a memoria) |
| **Directo** | EA = dirección fija en la instrucción | `MOV ax, [var_x]` | AX = 0xFFFF |
| **Indirecto por registro** | EA = contenido del registro (puntero) | `MOV ax, [si]` | AX = 0x0055 (85) con SI apuntando a nota1 |
| **Indexado** | EA = Base + Índice (+ desplazamiento) | `MOV ax, [bx + si]` | AX = 0x001E (30) para array[2] |

---

## Descripción de los Modos Implementados

### Modo 1 — Inmediato

El operando está **embebido directamente en el opcode** de la instrucción. No se genera ningún acceso adicional a memoria de datos. Al desensamblar con `U 100` en DEBUG, el valor constante es visible dentro del propio código de máquina.

```nasm
MOV ax, 100      ; AX = 0x0064 — el valor 64h está en el opcode
MOV bx, 0A5h     ; BX = 0x00A5
ADD cx, 55       ; CX += 55
AND dx, 00FFh    ; máscara inmediata
```

> **Verificación DEBUG:** `U 100` → observar `MOV AX,0064` — el 64h aparece directamente en el byte de la instrucción.

---

### Modo 2 — Directo

La instrucción contiene la **dirección absoluta** del operando. La dirección efectiva es fija en tiempo de compilación y aparece explícitamente en el opcode al desensamblar.

```nasm
MOV ax, [var_x]        ; AX ← mem[dir_var_x] = 0xFFFF
MOV bx, [array]        ; BX ← mem[dir_array]  = 10
MOV cx, [nota1]        ; CX ← mem[dir_nota1]  = 85
MOV [var_x], word 0    ; escribe 0 en la dirección de var_x
```

> **Verificación DEBUG:** `U` → observar `MOV AX,[01XX]` — la dirección del símbolo se ve en el opcode. `D DS:dir_array` → mostrar los bytes del array.

---

### Modo 3 — Indirecto por Registro

El registro **contiene la dirección** del operando (actúa como puntero). La dirección no está fija en la instrucción; puede cambiar en tiempo de ejecución, lo que permite acceso dinámico a memoria.

```nasm
MOV si, nota1     ; SI = dirección de nota1 (no su valor)
MOV ax, [si]      ; AX ← mem[SI] = 85

MOV si, nota2     ; SI ahora apunta a nota2
MOV bx, [si]      ; BX ← mem[SI] = 73

ADD ax, bx        ; AX = 85 + 73 = 158
SHR ax, 1         ; AX = 79 (promedio)

MOV si, promedio  ; SI = dirección de promedio
MOV [si], ax      ; mem[SI] = 79 — escritura vía puntero
```

#### Traza paso a paso (Checkpoint 2)

| Instrucción | Registro modificado | Valor resultante |
|---|---|---|
| `MOV si, nota1` | SI | dirección de nota1 (ej. 0x010D) |
| `MOV ax, [si]` | AX | 0x0055 (85 decimal) |
| `MOV si, nota2` | SI | dirección de nota2 (ej. 0x010F) |
| `MOV bx, [si]` | BX | 0x0049 (73 decimal) |
| `ADD ax, bx` | AX | 0x009E (158 decimal) |
| `SHR ax, 1` | AX | 0x004F (79 decimal) |
| `MOV [si], ax` | mem[SI] | 0x004F escrito en promedio |

> **Verificación DEBUG:** `T` paso a paso — observar cómo SI cambia entre instrucciones. `D DS:dir_promedio` → confirmar que el valor 0x004F fue escrito.

---

### Modo 4 — Indexado (Base + Índice + Desplazamiento)

La dirección efectiva se calcula combinando un **registro base** (BX) con un **registro índice** (SI) y opcionalmente un desplazamiento constante. Permite recorrer arrays y acceder a campos de estructuras de forma sistemática.

**Acceso a elemento específico:**
```nasm
MOV bx, array    ; BX = dirección base del array
MOV si, 4        ; SI = índice × sizeof(word) = 2 × 2 = 4
MOV ax, [bx+si]  ; AX = array[2] = 30   →   EA = BX + SI
```

**Suma acumulada del array completo:**
```nasm
XOR ax, ax         ; AX = 0 (acumulador)
MOV bx, array      ; BX = dirección base
MOV cx, 5          ; CX = número de elementos
XOR si, si         ; SI = 0 (índice de bytes)
.bucle_array:
    ADD ax, [bx+si] ; AX += array[SI/2]
    ADD si, 2       ; avanzar 2 bytes (tamaño word)
    LOOP .bucle_array
; Resultado: AX = 10+20+30+40+50 = 150 (0x0096)
```

**Acceso a campos de struct con desplazamiento fijo:**
```nasm
MOV bx, nota1     ; BX = base del struct
MOV ax, [bx]      ; AX = nota1    = 85  (offset 0)
MOV cx, [bx + 2]  ; CX = nota2    = 73  (offset 2)
MOV dx, [bx + 4]  ; DX = promedio = 79  (offset 4)
```

> **Verificación DEBUG:** trazar el bucle con `T` y confirmar AX=0x0096 (150) al terminar. Verificar también acceso a los campos del struct por desplazamiento.

---

## Extensión: Recorrido Inverso del Array (Checkpoint 3)

El bucle de suma fue modificado para recorrer el array desde `array[4]` hacia `array[0]`, decrementando el índice en 2 bytes por iteración:

```nasm
XOR ax, ax          ; AX = 0 (acumulador)
MOV bx, array       ; BX = dirección base
MOV cx, 5           ; CX = número de elementos
MOV si, 8           ; SI = offset del último elemento (4 × 2 = 8)
.bucle_inverso:
    ADD ax, [bx+si] ; AX += array[SI/2]
    SUB si, 2       ; retroceder 2 bytes
    LOOP .bucle_inverso
; Resultado: AX = 50+40+30+20+10 = 150 (igual, suma es conmutativa)
```

La suma es la misma (150) ya que la adición es conmutativa, pero el orden de acceso a memoria es el inverso, demostrable trazando con DEBUG y observando cómo SI decrece en cada iteración.

---

## Commits del Repositorio

```
feat: estructura base del programa y definición de datos en memoria
feat: modos inmediato y directo con verificación en DEBUG
feat: modo indirecto por registro con cálculo de promedio
feat: modo indexado — suma de array y acceso a struct
feat: recorrido inverso del array (extensión Checkpoint 3)
docs: agregar README con tabla de modos y trazas DEBUG
```

---

## Licencia

Actividad académica — Universidad Francisco de Paula Santander, 2026.
