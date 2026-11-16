# ERRORES DEL MOTOR CON PILA EN EL JUEGO (16-11-2026, informe académico, cap. 5 § 5.3.3).
# Lee la lista blanca (1.er archivo) y el registro limpio del banco (2.º, «-» = entrada estándar).
# Un bloque es una línea «ERROR: …» (o «USER ERROR: …») y las líneas sangradas que la siguen
# (`at:`, la pila de GDScript). Cuenta los bloques cuya pila pasa por res:// y que NO casan con
# ninguna entrada de la lista blanca; imprime los primeros y termina con «INESPERADOS n».
#   awk -f herramientas/errores_banco.awk pruebas/errores_esperados.txt registro.txt
# Lista blanca: «texto del mensaje<TAB>texto de la pila» (literales; el segundo puede ir vacío).
{ sub(/\r$/, "") }   # fin de línea de Windows (Git Bash)
FILENAME == ARGV[1] {   # (no `FNR == NR`: con la lista vacía también valdría para el registro)
	if ($0 ~ /^[ \t]*(#|$)/) next
	n = split($0, c, "\t")
	nb++; bm[nb] = c[1]; bp[nb] = (n > 1 ? c[2] : "")
	next
}
function cerrar(   i, ok) {
	if (cab == "") return
	if (pila ~ /res:\/\//) {
		ok = 0
		for (i = 1; i <= nb && !ok; i++)
			if (index(cab, bm[i]) && (bp[i] == "" || index(pila, bp[i]))) { ok = 1; usadas[i]++ }
		if (!ok) {
			malos++
			if (malos <= 8) { print cab; print substr(primeras, 1, 600) }
		}
	}
	cab = ""; pila = ""; primeras = ""; nl = 0
}
/^(USER )?ERROR: / { cerrar(); cab = $0; next }
cab != "" && /^[ \t]/ { pila = pila "\n" $0; if (++nl <= 4) primeras = primeras $0 "\n"; next }
{ cerrar() }
END {
	cerrar()
	print "INESPERADOS " (malos + 0)
}
