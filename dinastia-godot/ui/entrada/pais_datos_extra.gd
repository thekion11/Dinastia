class_name PaisDatosExtra
extends RefCounted
## (15-11-2026, pedido del dueño: «¿están todos los países?») La pantalla de país y el globo solo conocían 50 países, pero hay 135 con liga
## (`LigasActivas.todos()`): los otros 85 no se podían elegir. Aquí va lo mínimo de cada uno para la lista y el pin: nombre completo,
## capital, longitud y latitud de la capital (grados) y el grupo de la lista (el mismo de `PaisDatos.CONTINENTES`). Sin monumentos propios:
## el fondo enseña su bandera y nada delante (`PaisFondo` ya lo admite). Agrupados como en la lista: los de la UEFA en Europa.
const EXTRA := {
	"IRL": ["Irlanda", "Dublín", -6.26, 53.35, "Europa"], "WAL": ["Gales", "Cardiff", -3.18, 51.48, "Europa"],
	"NIR": ["Irlanda del Norte", "Belfast", -5.93, 54.60, "Europa"], "FIN": ["Finlandia", "Helsinki", 24.94, 60.17, "Europa"],
	"CYP": ["Chipre", "Nicosia", 33.37, 35.17, "Europa"], "SVN": ["Eslovenia", "Liubliana", 14.51, 46.06, "Europa"],
	"ALB": ["Albania", "Tirana", 19.82, 41.33, "Europa"], "AZE": ["Azerbaiyán", "Bakú", 49.87, 40.41, "Europa"],
	"BIH": ["Bosnia y Herzegovina", "Sarajevo", 18.41, 43.86, "Europa"], "BLR": ["Bielorrusia", "Minsk", 27.56, 53.90, "Europa"],
	"EST": ["Estonia", "Tallin", 24.75, 59.44, "Europa"], "GEO": ["Georgia", "Tiflis", 44.79, 41.72, "Europa"],
	"ISL": ["Islandia", "Reikiavik", -21.94, 64.15, "Europa"], "KAZ": ["Kazajistán", "Astaná", 71.45, 51.17, "Europa"],
	"LTU": ["Lituania", "Vilna", 25.28, 54.69, "Europa"], "LUX": ["Luxemburgo", "Luxemburgo", 6.13, 49.61, "Europa"],
	"LVA": ["Letonia", "Riga", 24.11, 56.95, "Europa"], "MKD": ["Macedonia del Norte", "Skopie", 21.43, 42.00, "Europa"],
	"MNE": ["Montenegro", "Podgorica", 19.26, 42.44, "Europa"], "ARM": ["Armenia", "Ereván", 44.51, 40.18, "Europa"],
	"MDA": ["Moldavia", "Chisináu", 28.86, 47.01, "Europa"], "AND": ["Andorra", "Andorra la Vieja", 1.52, 42.51, "Europa"],
	"FRO": ["Islas Feroe", "Tórshavn", -6.77, 62.01, "Europa"], "GIB": ["Gibraltar", "Gibraltar", -5.35, 36.14, "Europa"],
	"KOS": ["Kosovo", "Pristina", 21.17, 42.66, "Europa"], "MLT": ["Malta", "La Valeta", 14.51, 35.90, "Europa"],
	"SMR": ["San Marino", "San Marino", 12.45, 43.94, "Europa"],
	"SUR": ["Surinam", "Paramaribo", -55.20, 5.85, "Sudamérica"],
	"CAN": ["Canadá", "Ottawa", -75.70, 45.42, "Norteamérica"], "CRC": ["Costa Rica", "San José", -84.09, 9.93, "Norteamérica"],
	"HON": ["Honduras", "Tegucigalpa", -87.21, 14.07, "Norteamérica"], "JAM": ["Jamaica", "Kingston", -76.79, 17.97, "Norteamérica"],
	"PAN": ["Panamá", "Ciudad de Panamá", -79.52, 8.98, "Norteamérica"], "ESA": ["El Salvador", "San Salvador", -89.19, 13.69, "Norteamérica"],
	"GUA": ["Guatemala", "Ciudad de Guatemala", -90.51, 14.63, "Norteamérica"], "CUW": ["Curazao", "Willemstad", -68.93, 12.11, "Norteamérica"],
	"HAI": ["Haití", "Puerto Príncipe", -72.34, 18.54, "Norteamérica"], "NCA": ["Nicaragua", "Managua", -86.25, 12.13, "Norteamérica"],
	"TRI": ["Trinidad y Tobago", "Puerto España", -61.52, 10.66, "Norteamérica"],
	"IRQ": ["Irak", "Bagdad", 44.36, 33.31, "Asia"], "JOR": ["Jordania", "Amán", 35.93, 31.95, "Asia"],
	"UZB": ["Uzbekistán", "Taskent", 69.24, 41.30, "Asia"], "BHR": ["Baréin", "Manama", 50.59, 26.23, "Asia"],
	"IDN": ["Indonesia", "Yakarta", 106.85, -6.21, "Asia"], "IND": ["India", "Nueva Delhi", 77.21, 28.61, "Asia"],
	"MAS": ["Malasia", "Kuala Lumpur", 101.69, 3.14, "Asia"], "OMA": ["Omán", "Mascate", 58.41, 23.59, "Asia"],
	"THA": ["Tailandia", "Bangkok", 100.50, 13.76, "Asia"], "VIE": ["Vietnam", "Hanói", 105.85, 21.03, "Asia"],
	"HKG": ["Hong Kong", "Hong Kong", 114.17, 22.32, "Asia"], "KGZ": ["Kirguistán", "Biskek", 74.59, 42.87, "Asia"],
	"KUW": ["Kuwait", "Kuwait", 47.98, 29.38, "Asia"], "LBN": ["Líbano", "Beirut", 35.50, 33.89, "Asia"],
	"PHI": ["Filipinas", "Manila", 120.98, 14.60, "Asia"], "PLE": ["Palestina", "Ramala", 35.20, 31.90, "Asia"],
	"SGP": ["Singapur", "Singapur", 103.82, 1.35, "Asia"], "SYR": ["Siria", "Damasco", 36.29, 33.51, "Asia"],
	"TJK": ["Tayikistán", "Dusambé", 68.78, 38.56, "Asia"],
	"ALG": ["Argelia", "Argel", 3.06, 36.75, "África"], "CIV": ["Costa de Marfil", "Yamusukro", -5.28, 6.82, "África"],
	"CMR": ["Camerún", "Yaundé", 11.50, 3.87, "África"], "GHA": ["Ghana", "Acra", -0.19, 5.60, "África"],
	"NGA": ["Nigeria", "Abuya", 7.49, 9.06, "África"], "SEN": ["Senegal", "Dakar", -17.44, 14.69, "África"],
	"TUN": ["Túnez", "Túnez", 10.18, 36.81, "África"], "MLI": ["Malí", "Bamako", -8.00, 12.64, "África"],
	"BFA": ["Burkina Faso", "Uagadugú", -1.52, 12.37, "África"], "COD": ["RD del Congo", "Kinsasa", 15.31, -4.32, "África"],
	"GUI": ["Guinea", "Conakri", -13.68, 9.64, "África"], "KEN": ["Kenia", "Nairobi", 36.82, -1.29, "África"],
	"ZAM": ["Zambia", "Lusaka", 28.32, -15.39, "África"], "ANG": ["Angola", "Luanda", 13.23, -8.84, "África"],
	"BEN": ["Benín", "Porto Novo", 2.63, 6.50, "África"], "CGO": ["Congo", "Brazzaville", 15.28, -4.27, "África"],
	"CPV": ["Cabo Verde", "Praia", -23.51, 14.93, "África"], "GAB": ["Gabón", "Libreville", 9.45, 0.39, "África"],
	"LBY": ["Libia", "Trípoli", 13.19, 32.89, "África"], "MAD": ["Madagascar", "Antananarivo", 47.52, -18.88, "África"],
	"MOZ": ["Mozambique", "Maputo", 32.57, -25.97, "África"], "NAM": ["Namibia", "Windhoek", 17.08, -22.56, "África"],
	"TAN": ["Tanzania", "Dodoma", 35.75, -6.16, "África"], "TOG": ["Togo", "Lomé", 1.22, 6.13, "África"],
	"UGA": ["Uganda", "Kampala", 32.58, 0.35, "África"], "ZIM": ["Zimbabue", "Harare", 31.05, -17.83, "África"],
	"NZL": ["Nueva Zelanda", "Wellington", 174.78, -41.29, "Oceanía"],
}

static func coord(p: String) -> Vector2:
	var f: Array = EXTRA.get(p, [])
	return Vector2(float(f[2]), float(f[3])) if not f.is_empty() else Vector2.ZERO
