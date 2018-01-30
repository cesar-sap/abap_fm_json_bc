class ZCX_JSON_BC definition
  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

public section.

  constants ZCX_JSON_BC type SOTR_CONC value '763D495D64041ED881B43BCB536BD61B' ##NO_TEXT.
  data MESSAGE type STRING value 'undefined' ##NO_TEXT.

  methods CONSTRUCTOR
    importing
      !TEXTID like TEXTID optional
      !PREVIOUS like PREVIOUS optional
      !MESSAGE type STRING default 'undefined' .
protected section.
private section.
ENDCLASS.



CLASS ZCX_JSON_BC IMPLEMENTATION.


  method CONSTRUCTOR.
CALL METHOD SUPER->CONSTRUCTOR
EXPORTING
TEXTID = TEXTID
PREVIOUS = PREVIOUS
.
 IF textid IS INITIAL.
   me->textid = ZCX_JSON_BC .
 ENDIF.
me->MESSAGE = MESSAGE .
  endmethod.
ENDCLASS.
