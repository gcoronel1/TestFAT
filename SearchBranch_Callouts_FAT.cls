/**
 * CreateNewBranch_Callouts_FAT. 
 * <p /><p />
 * Modification log:<p />
 * -------------------------------------------------------------------------------------<p />
 * Developer                    Date                Description<p />
 * -------------------------------------------------------------------------------------<p />
 * Gabriel Coronel              08/17/2017      Original Version.<p />
 *
 * @author Gabriel Coronel
 */
global class SearchBranch_Callouts_FAT {

    public Feature_Branch_FAT__c objFeatureBranch;

    public SearchBranch_Callouts_FAT(ApexPages.StandardController objStandardController) {
        objFeatureBranch = (Feature_Branch_FAT__c)objStandardController.getRecord();
    }

    webService static Integer getList(String strBranchName) {
        Integer intCount = 0;
        try {
            SearchBranch_Callouts_FAT.getBranchList(strBranchName);
            intCount = 1;
        } catch(Exception objException) {
            System.debug('Exception --> ' + objException);
        }
        return intCount;
    }

    @future (callout = true)
    public static void getBranchList(String strBranchSearchName) {
        List<WrapperTreeElement> lstWrapperTreeElements = new List<WrapperTreeElement>();
        List<WrapperElement> lstWraperElement = new List<WrapperElement>();
        String strURL = 'https://api.github.com/repos/gcoronel1/TestFAT/git/trees/' + strBranchSearchName;

        //Create Http Request.
        HttpRequest objHttpRequest = new HttpRequest();
        objHttpRequest.setEndpoint(strURL);
        objHttpRequest.setMethod('GET');

        Http objHttp = new Http();
        HttpResponse objHttpResponse = new HttpResponse();
        objHttpResponse = objHttp.send(objHttpRequest);
        System.debug('Response repository --> ' + objHttpResponse.getBody());
        lstWrapperTreeElements = SearchBranch_Callouts_FAT.getBranchTree(objHttpResponse.getBody());
        if (!lstWrapperTreeElements.isEmpty()) {
            lstWraperElement = SearchBranch_Callouts_FAT.associateExtension(lstWrapperTreeElements);
            SearchBranch_Callouts_FAT.addComponents(lstWraperElement, strBranchSearchName);
        } else {
        }
    }

    /**
     * Method to obtain the file type associated with the extension.
     */
    public static List<WrapperElement> associateExtension(List<WrapperTreeElement> lstWrapperTreeElements) {
        List<WrapperElement> lstWraperElement = new List<WrapperElement>();
        Component_FAT__c objComponent = new Component_FAT__c();
        for(WrapperTreeElement objElemet : lstWrapperTreeElements) {
            String strFileName = objElemet.path.substringBeforeLast('.');
            String strFileExtension = objElemet.path.substringAfterLast('.');
            WrapperElement objWrapperElement = new WrapperElement();
            objWrapperElement.strName = strFileName;
            objWrapperElement.strType = SearchBranch_Callouts_FAT.getType(strFileExtension);
            objWrapperElement.strExtension = strFileExtension;
            lstWraperElement.add(objWrapperElement);
        }
        System.debug('List Wrapper Element --> ' + lstWraperElement);
        return lstWraperElement;
    }

    /**
     * Method to insert new components.
     */
    public static void addComponents(List<WrapperElement> lstWraperElement, String strBranchName) {
        if(!lstWraperElement.isEmpty()) {
            for(WrapperElement objElemet : lstWraperElement) {
                try {
                    Component_FAT__c objComponent = [SELECT Name, Type_FAT__c, Extension_FAT__c, API_Name_FAT__c FROM Component_FAT__c WHERE API_Name_FAT__c = :objElemet.strName AND Type_FAT__c = :objElemet.strType];
                    SearchBranch_Callouts_FAT.addFeatureBranchComponent(objComponent, strBranchName);
                    System.debug('Insertando objeto existente');
                } catch (Exception objException) {
                    if(objElemet.strType != 'file') {
                        Component_FAT__c objInsertComponent = new Component_FAT__c();
                        objInsertComponent.API_Name_FAT__c = objElemet.strName;
                        objInsertComponent.Type_FAT__c = objElemet.strType;
                        objInsertComponent.Extension_FAT__c = objElemet.strExtension;
                        insert objInsertComponent;
                        SearchBranch_Callouts_FAT.addFeatureBranchComponent(objInsertComponent, strBranchName);
                        System.debug('Insertando objeto nuevo');
                    }
                }
            }
        }
    }

    public static void addFeatureBranchComponent(Component_FAT__c objComponent, String strBranchName) {
        Id idFeatureBranch;
        Id idComponent;
        Feature_Branch_Component_FAT__c objFeatureBranchComponent =  new Feature_Branch_Component_FAT__c();
        Feature_Branch_Component_FAT__c objExistingFeatureBranchComponent =  new Feature_Branch_Component_FAT__c();
        try {
            idFeatureBranch = [SELECT Id FROM Feature_Branch_FAT__c WHERE Name = :strBranchName LIMIT 1].Id;
            idComponent = [SELECT Id FROM Component_FAT__c WHERE API_Name_FAT__c = :objComponent.API_Name_FAT__c AND Type_FAT__c = :objComponent.Type_FAT__c LIMIT 1].Id;
            objFeatureBranchComponent.RecordType = [SELECT Id, Name, SobjectType FROM RecordType WHERE Name = 'Component' AND SobjectType = 'Feature_Branch_Component_FAT__c' LIMIT 1];
            objFeatureBranchComponent.Component_FAT__c = idComponent;
            objFeatureBranchComponent.Feature_Branch_FAT__c = idFeatureBranch;
            try {
                objExistingFeatureBranchComponent = [SELECT Name, Id FROM Feature_Branch_Component_FAT__c WHERE Component_FAT__c = :objFeatureBranchComponent.Component_FAT__c AND 
                        Feature_Branch_FAT__c = :objFeatureBranchComponent.Feature_Branch_FAT__c];
            } catch (Exception objException) {
                insert objFeatureBranchComponent;
            }
        } catch (Exception objException) {
            System.debug('Exception --> ' + objException);
        }
    }

    /**
     * Method to get component extension.
     *
     * @param String    strExtension
     * @return String of component extension
     */
    public static String getType(String strExtension) {
        Map<String,List<String>> mapDependentOptions = new Map<String,List<String>>();
        mapDependentOptions = SearchBranch_Callouts_FAT.getDependentOptions();
        for (String strValue : mapDependentOptions.keySet()) {
            List<String> lstTemporal = mapDependentOptions.get(strValue);
            if(!lstTemporal.isEmpty()) {
                if(lstTemporal.get(0) == strExtension) {
                    return strValue;
                }
            }
        }
        return 'file';
    }

    /**
     * Method to get repository hash.
     *
     * @param String    strJSONBranchInformation.
     * @return List of wrapper tree elements.
     */
    public static List<WrapperTreeElement> getBranchTree(String strJSONBranchInformation) {
        WrapperTreeReponse objTreeResponse = (WrapperTreeReponse)System.JSON.deserialize(strJSONBranchInformation, WrapperTreeReponse.class);
        return objTreeResponse.tree;
    }

    /**
     * Method to get dependent picklist.
     */
    public static Map<String,List<String>> getDependentOptions() {
        Map<String,List<String>> mapDependentOptions = new Map<String,List<String>>();
        Schema.DescribeFieldResult objExtensionDescribe = Component_FAT__c.Extension_FAT__c.getDescribe();
        Schema.DescribeFieldResult objTypeDescribe = Component_FAT__c.Type_FAT__c.getDescribe();
        mapDependentOptions = GetDependentOptionsUntil_FAT.getDependentOptions(objExtensionDescribe.getSObjectField(), objTypeDescribe.getSObjectField());
        return mapDependentOptions;
    }

    /**
     * Tree response wrapper class.
     */
    public class WrapperTreeReponse {

        //Public variables.
        public String sha;
        public String url;
        public String truncated;
        public List<WrapperTreeElement> tree;
    }

    /**
     * Tree element wrapper class.
     */
    public class WrapperTreeElement {

        //Public variables.
        public String mode {get; set;}
        public String path {get; set;}
        public String sha {get; set;}
        public String size {get; set;}
        public String type {get; set;}
        public String url {get; set;}
    }

    /**
     * Display wrapper class.
     */
    public class WrapperElement {

        //Public variables.
        public String strExtension;
        public String strType {get; set;}
        public String strName {get; set;}
    }
}