CLASS zcl_printsales_integration DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS: fetch_data_from_backend IMPORTING zsalesdoc TYPE string RETURNING VALUE(r_blob) TYPE string,
      create_xml_body IMPORTING odata_response TYPE zzbes_zz1_salestracking2 RETURNING VALUE(r_xml) TYPE string,
      get_pdf_template IMPORTING template_name TYPE string RETURNING VALUE(r_string) TYPE string.

    TYPES :
      BEGIN OF ads_struct,
        xdp_Template TYPE string,
        xml_Data     TYPE string,
        form_Type    TYPE string,
        form_Locale  TYPE string,
        tagged_Pdf   TYPE string,
        embed_Font   TYPE string,
      END OF ads_struct."

    CONSTANTS lc_ads_render TYPE string VALUE '/v1/adsRender/pdf'.
    CONSTANTS lc_storage_name TYPE string VALUE 'templateSource=storageName'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PRINTSALES_INTEGRATION IMPLEMENTATION.


  METHOD fetch_data_from_backend.
    DATA:
      ls_entity_key    TYPE zzbes_zz1_salestracking2,
      ls_business_data TYPE zzbes_zz1_salestracking2,
      lo_http_client   TYPE REF TO if_web_http_client,
      lo_resource      TYPE REF TO /iwbep/if_cp_resource_entity,
      lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request       TYPE REF TO /iwbep/if_cp_request_read,
      lo_response      TYPE REF TO /iwbep/if_cp_response_read.

    TRY.
        " Create http client
        " Details depend on your connection settings
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                                     comm_scenario  = 'ZSLS_TRACKING_BES'
                                                     comm_system_id = 'BES_HTTPS'
                                                     service_id     = 'ZSLS_TRACK_OUTBOUND_REST' ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).


        lo_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
          EXPORTING
            iv_service_definition_name = 'ZSLS_TRACKING'
            io_http_client             = lo_http_client
            iv_relative_service_root   = 'sap/opu/odata/sap/ZZ1_SALESTRACKING2_CDS' ).


        " Set entity key
        ls_entity_key = VALUE #(
                  salesdoc_key  = zsalesdoc ).

        " Navigate to the resource
        lo_resource = lo_client_proxy->create_resource_for_entity_set( 'ZZ1_SALESTRACKING2' )->navigate_with_key( ls_entity_key ).

        " Execute the request and retrieve the business data
        lo_response = lo_resource->create_request_for_read( )->execute( ).
        lo_response->get_business_data( IMPORTING es_business_data = ls_business_data ).

        r_blob = create_xml_body( ls_business_data ).


      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
        " Handle remote Exception
        " It contains details about the problems of your http(s) connection

      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        " Handle Exception

    ENDTRY.
  ENDMETHOD.


  METHOD create_xml_body.

    DATA: lxs_data_xml TYPE xstring,
          lxs_xdp      TYPE xstring,
          lxs_pdf      TYPE xstring,
          li_pages     TYPE int4,
          ls_trace     TYPE string.

    DATA(lv_xml_temp) = '<form1>' && |\n|  &&
                             '   <TextField1>i834429</TextField1>' && |\n|  &&
                             '   <TextField2>Si manu vacuas</TextField2>' && |\n|  &&
                             '   <TextField3>Apros tres et quidem</TextField3>' && |\n|  &&
                             '</form1>'.

    DATA(lv_xml) = cl_web_http_utility=>encode_base64( lv_xml_temp ).

    DATA(ls_body) = VALUE ads_struct( xdp_Template = 'zsample/zsample'
                                      xml_Data = lv_xml
                                      form_Type = 'print'
                                      form_Locale = 'en'
                                      tagged_Pdf = '0'
                                      embed_font = '0' ).

    DATA(lv_json) = /ui2/cl_json=>serialize( data = ls_body compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    TRY.
        "create http destination by url; API endpoint for API sandbox
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_cloud_destination(
                                      i_name                  = 'ADS_SRV'
                                      i_authn_mode            = if_a4c_cp_service=>service_specific
                                    ).
        "create HTTP client by destination
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .

        "adding headers
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_header_fields( VALUE #(
                                                        (  name = 'DataServiceVersion' value = '2.0' )
                                                        (  name = 'Accept' value = 'application/json' )
                                                        (  name = 'Content-Type' value = 'application/json' )
                                                        ) ).
        lo_web_http_request->set_query( query =  lc_storage_name ).
        lo_web_http_request->set_uri_path( i_uri_path = lc_ads_render ).

        lo_web_http_request->append_text(
          EXPORTING
            data   = lv_json
        ).

        "set request method and execute request
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
        DATA(lv_response) = lo_web_http_response->get_text( ).

        FIELD-SYMBOLS:
          <data>                TYPE data,
          <field>               TYPE any,
          <pdf_based64_encoded> TYPE any.

        "lv_json_response has the following structure `{"fileName":"PDFOut.pdf","fileContent":"JVB..."}

        DATA(lr_data) = /ui2/cl_json=>generate( json = lv_response ).

        IF lr_data IS BOUND.
          ASSIGN lr_data->* TO <data>.
          ASSIGN COMPONENT `fileContent` OF STRUCTURE <data> TO <field>.
          IF sy-subrc EQ 0.
            ASSIGN <field>->* TO <pdf_based64_encoded>.
             r_xml = <pdf_based64_encoded>.
          ENDIF.
        ENDIF.

      CATCH cx_root INTO DATA(lx_exception).

    ENDTRY.

  ENDMETHOD.


  METHOD get_pdf_template.

*    TRY.
*        "create http destination by url; API endpoint for API sandbox
*        DATA(lo_http_destination) =
*             cl_http_destination_provider=>create_by_url( 'https://adsrestapi-formsprocessing.cfapps.eu10.hana.ondemand.com/v1/forms/zsample/templates/zsample' ).
*        "alternatively create HTTP destination via destination service
*        "cl_http_destination_provider=>create_by_cloud_destination( i_name = '<...>'
*        "                            i_service_instance_name = '<...>' )
*        "SAP Help: https://help.sap.com/viewer/65de2977205c403bbc107264b8eccf4b/Cloud/en-US/f871712b816943b0ab5e04b60799e518.html
*
*        "create HTTP client by destination
*        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
*
*        "adding headers
*        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
*        lo_web_http_request->set_header_fields( VALUE #(
*(  name = 'Authorization' value = 'Bearer eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vczRocmlnLWFtci0wMDIuYXV0aGVudGljYXRpb24uZXUxMC5oYW5hLm9uZGVtYW5kLmNvbS90b2tlbl9rZXlzIiwia2lkIjoiZGVmYXVsdC1qd3Qta2V5LTQ2MjUzNzM4NyIsInR5cCI6IkpXVCJ9.eyJqdGkiOiIwNzFmYT' &&
*'IxOGYwZjc0OTEwYjUwNzgxYzgyZmVjZjg2NyIsImV4dF9hdHRyIjp7ImVuaGFuY2VyIjoiWFNVQUEiLCJzdWJhY2NvdW50aWQiOiI0NzZjMGYxOC0xZWE5LTRmZjEtOTJkMi02NGY3NDk1MGZkN2IiLCJ6ZG4iOiJzNGhyaWctYW1yLTAwMiIsInNlcnZpY2VpbnN0YW5jZWlkIjoiODJjMGI2NjctMTFlNC00NmQ3LWE4NDktNzUwNj' &&
*'U3NDRmMmIwIn0sInN1YiI6InNiLTgyYzBiNjY3LTExZTQtNDZkNy1hODQ5LTc1MDY1NzQ0ZjJiMCFiMTMwNDM5fGFkcy14c2FwcG5hbWUhYjEwMjQ1MiIsImF1dGhvcml0aWVzIjpbInVhYS5yZXNvdXJjZSIsImFkcy14c2FwcG5hbWUhYjEwMjQ1Mi5UZW1wbGF0ZVN0b3JlQ2FsbGVyIiwiYWRzLXhzYXBwbmFtZSFiMTAyNDUyLk' &&
*'FEU0NhbGxlciJdLCJzY29wZSI6WyJ1YWEucmVzb3VyY2UiLCJhZHMteHNhcHBuYW1lIWIxMDI0NTIuVGVtcGxhdGVTdG9yZUNhbGxlciIsImFkcy14c2FwcG5hbWUhYjEwMjQ1Mi5BRFNDYWxsZXIiXSwiY2xpZW50X2lkIjoic2ItODJjMGI2NjctMTFlNC00NmQ3LWE4NDktNzUwNjU3NDRmMmIwIWIxMzA0Mzl8YWRzLXhzYXBwbm' &&
*'FtZSFiMTAyNDUyIiwiY2lkIjoic2ItODJjMGI2NjctMTFlNC00NmQ3LWE4NDktNzUwNjU3NDRmMmIwIWIxMzA0Mzl8YWRzLXhzYXBwbmFtZSFiMTAyNDUyIiwiYXpwIjoic2ItODJjMGI2NjctMTFlNC00NmQ3LWE4NDktNzUwNjU3NDRmMmIwIWIxMzA0Mzl8YWRzLXhzYXBwbmFtZSFiMTAyNDUyIiwiZ3JhbnRfdHlwZSI6ImNsaW' &&
*'VudF9jcmVkZW50aWFscyIsInJldl9zaWciOiJjOWI0Njg1ZiIsImlhdCI6MTY1ODUwNTIzOCwiZXhwIjoxNjU4NTQ4NDM4LCJpc3MiOiJodHRwczovL3M0aHJpZy1hbXItMDAyLmF1dGhlbnRpY2F0aW9uLmV1MTAuaGFuYS5vbmRlbWFuZC5jb20vb2F1dGgvdG9rZW4iLCJ6aWQiOiI0NzZjMGYxOC0xZWE5LTRmZjEtOTJkMi02NG' &&
*'Y3NDk1MGZkN2IiLCJhdWQiOlsidWFhIiwiYWRzLXhzYXBwbmFtZSFiMTAyNDUyIiwic2ItODJjMGI2NjctMTFlNC00NmQ3LWE4NDktNzUwNjU3NDRmMmIwIWIxMzA0Mzl8YWRzLXhzYXBwbmFtZSFiMTAyNDUyIl19.RPa0679-N33H85hkX-85gnKHELUDo3riGZGD45ZFrFF-TcnZRDz6g3l0fAy70_yOPmV8Ra0cVYr5K6N8M2z5R' &&
*'8aTIsmfMtnZkQseYBR8DeqbDazgVg6LRjB4O_eLFzu-I2lXZJxa_M70Tx7jUUgk9B0-F60VLSIffU4GzJJg1gOBpzl7INS66GpuXg5cgxILPaxqXLqVaJTFkWFYWrq7Ix0vhTAn7GSXX1he2xXcZdbMY7bZTDk4OAZmequD0LgL8VBzulYxEI5KWKgDh_b-M2sHLzlnM1x8zFoT59q6c9h3Xa7lDC2ZQD_jjsplMlEJVLs4erzSavAxF' &&
*'Xjrr-VtlQ' )
*  (  name = 'DataServiceVersion' value = '2.0' )
*  (  name = 'Accept' value = 'application/json' )
*   ) ).
*
*        "set request method and execute request
*        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
*        DATA(lv_response) = lo_web_http_response->get_text( ).
*
*        DATA lr_data TYPE REF TO data.
*        DATA lr_field TYPE REF TO data.
*
*        lr_data = /ui2/cl_json=>generate( json = lv_response ).
*
*        FIELD-SYMBOLS:
*          <data>                TYPE data,
*          <template>            TYPE any,
*          <table>               TYPE ANY TABLE,
*          <structure>           TYPE any,
*          <field>               TYPE any,
*          <field_value>         TYPE any,
*          <pdf_based64_encoded> TYPE any.
*
*        IF lr_data IS BOUND.
*          ASSIGN lr_data->* TO <data>.
*          ASSIGN COMPONENT 'XDPTEMPLATE' OF STRUCTURE <data> TO <template>.
*          IF sy-subrc EQ 0.
*            ASSIGN <template>->* TO <field_value>.
*            r_string = <field_value>.
*          ENDIF.
**          r_string = cl_abap_conv_codepage=>create_out(  )->convert( <field>->* ).
**          r_string = <data>.
**          ASSIGN COMPONENT 'TEMPLATES' OF STRUCTURE <data> TO <template>.
**          IF sy-subrc EQ 0.
**            ASSIGN <template>->* TO <table>.
**
**            LOOP AT <table> ASSIGNING <structure>.
**              ASSIGN <structure>->* TO <field>.
**              ASSIGN COMPONENT 'XDPTEMPLATE' OF STRUCTURE <field> TO <pdf_based64_encoded>.
**              IF <pdf_based64_encoded> IS ASSIGNED.
**                r_string = <pdf_based64_encoded>.
**              ENDIF.
**            ENDLOOP.
**          ENDIF.
*        ENDIF.
*
*      CATCH cx_root INTO DATA(lx_exception).
*    ENDTRY.
  ENDMETHOD.
ENDCLASS.
