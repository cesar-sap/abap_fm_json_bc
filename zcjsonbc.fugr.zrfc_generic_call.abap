FUNCTION ZRFC_GENERIC_CALL.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(PARAMTAB_STR) TYPE  STRING
*"     VALUE(FUNCNAME) TYPE  RS38L_FNAM
*"     VALUE(FORMAT) TYPE  STRING DEFAULT 'JSON'
*"     VALUE(JSONP_CALLBACK) TYPE  STRING
*"     VALUE(SHOW_IMPORT_PARAMS) TYPE  XFELD
*"     VALUE(LOWERCASE) TYPE  XFELD
*"     VALUE(CAMELCASE) TYPE  XFELD
*"  EXPORTING
*"     VALUE(RESULTTAB_STR) TYPE  STRING
*"     VALUE(CONTENT_TYPE) TYPE  STRING
*"     VALUE(EXCEPTAB_STR) TYPE  STRING
*"----------------------------------------------------------------------


data:
*        funcname       type rs38l_fnam,
    etext        type string,
    funcname2    type string,
    dparam       type abap_parmname,
    t_params_p   type standard table of rfc_fint_p,
    paramtab     type abap_func_parmbind_tab,
    exceptab     type abap_func_excpbind_tab,
    exception    type line of abap_func_excpbind_tab,
    exceptheader type string,
    funcrc       type sy-subrc,
    str_item     type string,
    oexcp        type ref to cx_root.

  field-symbols <fm_param> type abap_func_parmbind.
  field-symbols <fm_int_handler> type zicf_handler_data.


* Prepare params to call function
    call method zcl_json_handlerbc=>build_params
      exporting
        function_name    = funcname
      importing
        params           = t_params_p
        paramtab         = paramtab
        exceptab         = exceptab
      exceptions
        invalid_function = 1
        others           = 2.

    if sy-subrc <> 0.
      concatenate 'Invalid Function. ' sy-msgid sy-msgty sy-msgno ': '
              sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              into etext separated by '-'.
*    http_error '500' 'Server Error' etext.
    endif.



**********************
* Process input data *
**********************
    try.
        call method zcl_json_handlerbc=>json_deserialize     " The classic method using JavaScript (JSON only)
*      CALL METHOD me->deserialize_id  " The new method using transformation id. This method accepts both JSON and XML input!!! Great!!
          exporting
            json     = paramtab_str
          changing
            paramtab = paramtab.

      catch cx_root into oexcp.

        etext = oexcp->if_message~get_text( ).

*      http_error '500' 'Internal Server Error' etext.

    endtry.
*/**********************************/*
*/**********************************/*



****************************
* Call the function module *
****************************
    try.

        call function funcname
          parameter-table
          paramtab
          exception-table
          exceptab.

      catch cx_root into oexcp.

        etext = oexcp->if_message~get_longtext(  preserve_newlines = abap_true ).

*       me->http_error( http_code = '500' status_text = 'Internal Server Error'  message = etext ).

    endtry.


* Remove unused exceptions
    funcrc = sy-subrc.
    delete exceptab where value ne funcrc.
    read table exceptab into exception with key value = funcrc.
    if sy-subrc eq 0.
      exceptheader = exception-name.
*      call method me->server->response->set_header_field( name  = 'X-SAPRFC-Exception' value = exceptheader ).
    endif.



* Prepare response. Serialize to output format stream.
    case format.

      when 'YAML'.

        call method zcl_json_handlerbc=>serialize_yaml
          exporting
            paramtab    = paramtab
            exceptab    = exceptab
            params      = t_params_p
            jsonp       = jsonp_callback
            show_impp   = show_import_params
            lowercase   = lowercase
          importing
            yaml_string = RESULTTAB_STR.

        Content_Type = 'text/plain'.

      when 'PERL'.

        call method zcl_json_handlerbc=>serialize_perl
          exporting
            paramtab    = paramtab
            exceptab    = exceptab
            params      = t_params_p
            jsonp       = jsonp_callback
            show_impp   = show_import_params
            funcname    = funcname
            lowercase   = lowercase
          importing
            perl_string = RESULTTAB_STR.

       Content_Type = 'text/plain'.

      when 'XML'.

        call method zcl_json_handlerbc=>serialize_xml
*      CALL METHOD zcl_json_handlerbc=>serialize_id
          exporting
            paramtab  = paramtab
            exceptab  = exceptab
            params    = t_params_p
            jsonp     = jsonp_callback
            show_impp = show_import_params
            funcname  = funcname
            lowercase = lowercase
            format    = format
          importing
            o_string  = RESULTTAB_STR.

        Content_Type = 'application/xml'.

      when others. " the others default to JSON.

*      format = 'JSON'.
        call method zcl_json_handlerbc=>serialize_json
*      CALL METHOD zcl_json_handlerbc=>serialize_id
          exporting
            paramtab  = paramtab
            exceptab  = exceptab
            params    = t_params_p
            jsonp     = jsonp_callback
            show_impp = show_import_params
            lowercase = lowercase
*           format    = format
          importing
            o_string  = RESULTTAB_STR.

        Content_Type = 'application/json'.
        if jsonp_callback is not initial.
          Content_Type = 'application/javascript'.
        endif.

    endcase.







ENDFUNCTION.
