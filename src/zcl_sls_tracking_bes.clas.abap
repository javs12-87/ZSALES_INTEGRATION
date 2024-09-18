CLASS zcl_sls_tracking_bes DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SLS_TRACKING_BES IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA:
      ls_entity_key    TYPE ZZBES_ZZ1_SALESTRACKING2,
      ls_business_data TYPE ZZBES_ZZ1_SALESTRACKING2,
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
                  salesdoc_key  = '0060000000' ).

        " Navigate to the resource
        lo_resource = lo_client_proxy->create_resource_for_entity_set( 'ZZ1_SALESTRACKING2' )->navigate_with_key( ls_entity_key ).

        " Execute the request and retrieve the business data
        lo_response = lo_resource->create_request_for_read( )->execute( ).
        lo_response->get_business_data( IMPORTING es_business_data = ls_business_data ).

        out->write( ls_business_data ).

      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
        " Handle remote Exception
        " It contains details about the problems of your http(s) connection
        out->write( lx_remote->get_longtext( ) ).

      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        " Handle Exception
        out->write( lx_gateway->get_longtext(  ) ).

    ENDTRY.
  ENDMETHOD.
ENDCLASS.
