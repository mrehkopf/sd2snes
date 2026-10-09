; menu record types and table macros

; Menu entry structure
; Hook functions are stored as address-1 because they are called via RTL.
; the "target" field is type specific:
;
;  MTYPE     | meaning of "target"
;------------+---------------------------
; FUNC       | faraddr subroutine-1
; FUNC_CLOSE | faraddr subroutine-1
; SUBMENU    | (MenuHeader,MenuEntries)*
; VALUE      | OPTTYPE  |   meaning
;            +----------+----------------
;            | BYTE     | ValueRange*
;            | WORD     | ValueRange*
;            | STRING   | max length
;            | KVBYTE   | KVEntry**
;            | KVWORD   | KVEntry**
;            | FILESEL  | FileselSpec* [TODO]
;            | TIME     | (not used)
;

; TODO implement FileselSpec!
; 3 bytes: path*
; n bytes: zero-terminated list of desired file types (single byte constants)
;          (in accordance with SNES_FTYPE in filetypes.h)


MenuHeader .struct step, title
  step            .byte \step   ; UI hint: line spacing of entries (listsel_step)
  title           .long \title  ; window title
.ends

MenuEntry .struct type, text, target, dtype, value, desc, chg_func, post_func, isenabled_func
  type            .byte \type             ; MTYPE_*
  text            .long \text             ; label
  target          .long \target           ; type specific, see above
  dtype           .byte \dtype            ; OPTTYPE_* (OPTTYPE_NONE: no value shown)
  value           .long \value            ; pointer to the value
  desc            .long \desc             ; pointer to a description text (not yet shown)
  chg_func        .long \chg_func         ; called on each change during selection, address-1
  post_func       .long \post_func        ; called when the value is set, address-1
  isenabled_func  .long \isenabled_func   ; c=0: enabled, c=1: disabled, address-1
.ends

KVEntry .struct key, text               ; table ends with key $ffff
  key             .word \key            ; (OPTTYPE_KVBYTE only uses the low byte of key)
  text            .long \text
.ends

ValueRange .struct min, max
  min             .word \min
  max             .word \max
.ends

; menu functions step through these records with fixed inx/iny sequences
; (show_menu, menu_measure, menu_kv_lookup, menu_value_dialog_kv8)
; so add some sanity checks
.cerror size(MenuHeader) != 4, "MenuHeader size must be 4 (hardcoded in menu.asm)"
.cerror MenuEntry.target != 4, "MenuEntry.target offset must be 4 (hardcoded in show_menu)"
.cerror size(KVEntry) != 5, "KVEntry size must be 5 (hardcoded in menu.asm)"

; ---------------------------------------------------------------------------
; macros for convenient menu data definition:
;
; .menu_header     step, title
; .menu_func       text, routine, desc[, isenabled_func]
; .menu_func_close text, routine, desc[, isenabled_func]
; .menu_submenu    text, menu, desc[, isenabled_func]
; .menu_value      text, preset, dtype, value, desc[, chg_func, post_func, isenabled_func]
; .menu_entry      type, text, target, dtype, value, desc[, chg_func, post_func, isenabled_func]
; .menu_end
; hook functions and routines are referenced by name. (blank = none)

; hook function (called via RTL): address-1, or 0 without an argument
menu_hook .sfunction _f=0, _f != 0 ? _f - 1 : 0

menu_header .macro step, title
  .dstruct MenuHeader, \step, \title
.endm

menu_entry .macro type, text, target, dtype, value, desc, chg_func=, post_func=, isenabled_func=
  .dstruct MenuEntry, \type, \text, \target, \dtype, \value, \desc, menu_hook(\chg_func), menu_hook(\post_func), menu_hook(\isenabled_func)
.endm

menu_func .macro text, routine, desc, isenabled_func=
  .menu_entry MTYPE_FUNC, \text, \routine-1, OPTTYPE_NONE, 0, \desc, , , \isenabled_func
.endm

menu_func_close .macro text, routine, desc, isenabled_func=
  .menu_entry MTYPE_FUNC_CLOSE, \text, \routine-1, OPTTYPE_NONE, 0, \desc, , , \isenabled_func
.endm

menu_submenu .macro text, menu, desc, isenabled_func=
  .menu_entry MTYPE_SUBMENU, \text, \menu, OPTTYPE_NONE, 0, \desc, , , \isenabled_func
.endm

menu_value .macro text, preset, dtype, value, desc, chg_func=, post_func=, isenabled_func=
  .menu_entry MTYPE_VALUE, \text, \preset, \dtype, \value, \desc, \chg_func, \post_func, \isenabled_func
.endm

menu_end .macro
  .byte 0
.endm

; little helpers to fill basic structs
kv .macro key, text
  .dstruct KVEntry, \key, \text
.endm

kv_end .macro
  .word $ffff
.endm

value_range .macro min, max
  .dstruct ValueRange, \min, \max
.endm
