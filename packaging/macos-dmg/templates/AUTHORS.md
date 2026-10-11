# Autorzy i pochodzenie kodu FSVR

**FSVR (Formant Synthesizer Virtual Rack)** jest rekonstrukcją syntezatora
Yamaha FS1R jako wtyczki i konsoli, oparta na inżynierii wstecznej firmware'u
sprzętu.

## Autorzy projektu

- **James Hansen** ([github.com/jameshansen](https://github.com/jameshansen/))
  — twórca repozytorium FSVR (wrzesień 2026), autor przepisania logiki
  firmware'u na C++ na podstawie zdekompilowanego ROM-u.
- **Zhiyuan Wan** ([github.com/rgwan](https://github.com/rgwan/)) — autor
  oryginalnego projektu badawczego
  [rgwan/fs1r_firmware_RE](https://github.com/rgwan/fs1r_firmware_RE) (2025),
  który wydobył firmware z układu SH7044 i zrzucił zawartość zewnętrznego
  EPROM-u FS1R. Obecnie współpracuje z James Hansenem nad rozwojem silnika.

Repozytorium źródłowe: **https://github.com/musicastudio/FSVR**

## Licencja

Kod projektu FSVR jest udostępniony na licencji **GNU General Public
License v3 (GPL-3)** — patrz plik `LICENSE.txt` w tym pakiecie oraz
`NOTICE.md` po szczegóły dotyczące pochodzenia poszczególnych plików
(w tym danych wyodrębnionych z EPROM-u Yamahy, które nie są objęte
licencją autorów FSVR).

## Składniki innych autorów

Wtyczka AU zawiera biblioteki pobierane przy kompilacji, każda na własnej
licencji (szczegóły w `NOTICE.md`): clap-wrapper (MIT), Apple AudioUnitSDK
(Apache 2.0), dekodery dr_libs i stb_vorbis (domena publiczna / MIT-0),
a w interfejsie krój Saira (SIL OFL 1.1) i ikony Google Material Symbols
(Apache 2.0). Wbudowane brzmienia fabryczne (1408 głosów, 384 performance,
90 Fseq) to dane Yamahy wyodrębnione z EPROM-u — nie są objęte licencją
autorów FSVR.

Oficjalne wydania projektu (z własnym instalatorem) są na
https://github.com/musicastudio/FSVR/releases/latest.

## Znaki towarowe

Yamaha i FS1R są znakami towarowymi Yamaha Corporation. Ten projekt nie
jest powiązany z Yamahą, nie jest przez nią wspierany ani z nią afiliowany.

## Ten pakiet DMG

Ten instalator DMG oraz skrypt budujący go zostały przygotowane przy
pomocy Claude (Anthropic) jako narzędzie pakujące dla użytkownika końcowego
— **nie zmienia to w żaden sposób autorstwa kodu źródłowego wtyczki**,
które w całości należy do autorów wymienionych powyżej. Pełny kod źródłowy
jest dołączony do tego pakietu w folderze „Source Code”, zgodnie z
wymogami licencji GPL-3.
