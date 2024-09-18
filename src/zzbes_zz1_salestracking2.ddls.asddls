/********** GENERATED on 07/20/2022 at 19:17:49 by CB9980000000**************/
 @OData.entitySet.name: 'ZZ1_SalesTracking2' 
 @OData.entityType.name: 'ZZ1_SalesTracking2Type' 
 define root abstract entity ZZBES_ZZ1_SALESTRACKING2 { 
 key SalesDoc_key : abap.char( 10 ) ; 
 @OData.property.valueControl: 'SalesDocumentType_vc' 
 SalesDocumentType : abap.char( 4 ) ; 
 SalesDocumentType_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'CreatedByUser_vc' 
 CreatedByUser : abap.char( 12 ) ; 
 CreatedByUser_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'LastChangeDate_vc' 
 LastChangeDate : rap_cp_odata_v2_edm_datetime ; 
 LastChangeDate_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'SalesOrganization_vc' 
 SalesOrganization : abap.char( 4 ) ; 
 SalesOrganization_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'DistributionChannel_vc' 
 DistributionChannel : abap.char( 2 ) ; 
 DistributionChannel_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'OrganizationDivision_vc' 
 OrganizationDivision : abap.char( 2 ) ; 
 OrganizationDivision_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'SalesGroup_vc' 
 SalesGroup : abap.char( 3 ) ; 
 SalesGroup_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'SoldToParty_vc' 
 SoldToParty : abap.char( 10 ) ; 
 SoldToParty_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'calculatedstatus_vc' 
 calculatedstatus : abap.char( 20 ) ; 
 calculatedstatus_vc : rap_cp_odata_value_control ; 
 @OData.property.valueControl: 'totalamount_vc' 
 totalamount : abap.dec( 10, 2 ) ; 
 totalamount_vc : rap_cp_odata_value_control ; 
 ETAG__ETAG : abap.string( 0 ) ; 
 
 } 
