CLASS zcl_test_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
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

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
  METHODS get_root_exception
      IMPORTING
        !ix_exception  TYPE REF TO cx_root
      RETURNING
        VALUE(rx_root) TYPE REF TO cx_root .
ENDCLASS.



CLASS ZCL_TEST_API IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

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

    out->write( 'json payload' ).
    out->write( lv_json ).

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

        out->write( 'lv_json_response:' ).
        out->write( lo_web_http_response->get_text( ) ).

      CATCH cx_root INTO DATA(lx_exception).
        out->write( 'root exception' ).
        out->write( get_root_exception( lx_exception )->get_longtext(  ) ).
    ENDTRY.

  ENDMETHOD.


  METHOD get_root_exception.
    rx_root = ix_exception.
    WHILE rx_root->previous IS BOUND.
      rx_root ?= rx_root->previous.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
