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
public class CreateNewBranch_Callouts_FAT {

    public String strMessage {get; set;}

    public CreateNewBranch_Callouts_FAT(ApexPages.StandardController objStandardController) {
        getGitStatusMessage((Feature_Branch_FAT__c)objStandardController.getRecord());
    }

    public void getGitStatusMessage(Feature_Branch_FAT__c objFeatureBranch) {
        Feature_Branch_FAT__c objFeatureQuery = [SELECT Id, Name, Created_In_GitHub_FAT__c FROM Feature_Branch_FAT__c WHERE Id = :objFeatureBranch.Id];
        if(objFeatureQuery.Created_In_GitHub_FAT__c == true) {
            strMessage = 'The branch was created the repository with ' + objFeatureQuery.Name +' name.';
        } else {
             strMessage = 'Please create branch in GitHub';
        }
    }

    /**
     * Method to get repository information.
     *
     * @param String    strBranchName
     */
    @future (callout = true)
    public static void getContinuationRepository(String strBranchName) {
        Http objHttp = new Http();
        Http objCreateHttp = new Http();
        HttpRequest objHttpRequest = new HttpRequest();
        HttpRequest objCreateHttpRequest = new HttpRequest();
        HttpResponse objHttpResponse = new HttpResponse();
        HttpResponse objCreateHttpResponse = new HttpResponse();
        String strRequestBody = '';
        String strRepositoryHash = '';
        String strURL = 'https://api.github.com/repos/gcoronel1/TestFAT/git/refs/heads';

        //Create Http Request to get repository information.
        objHttpRequest.setEndpoint(strURL);
        objHttpRequest.setMethod('GET');
        try {
            objHttpResponse = objHttp.send(objHttpRequest);
            strRequestBody = objHttpResponse.getBody();
            System.debug('Response Body --> ' + objHttpResponse.getBody());
            if(String.IsNotBlank(strRequestBody)){
                strRepositoryHash = strRequestBody.subStringBetween('"sha":"','"');
            }
            String strCreateURL = 'https://api.github.com/repos/gcoronel1/TestFAT/git/refs';

            //Create Http Request to create new branch.
            Blob blobHeaderValue = Blob.valueOf('gcoronel1' + ':' + 'Ago.2017');
            String strAuthorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(blobHeaderValue);
            objCreateHttpRequest.setHeader('Authorization', strAuthorizationHeader);
            objCreateHttpRequest.setEndpoint(strCreateURL);
            objCreateHttpRequest.setMethod('POST');
            objCreateHttpRequest.setBody('{"ref": "refs/heads/' + strBranchName + '","sha": "' + '5ac4f63fe42ba16c7befc5bcd1a7666ffb5b875b' + '"}');
            try {
                objCreateHttpResponse = objCreateHttp.send(objCreateHttpRequest);
            } catch (Exception objException) {
                System.debug('Exception --> ' + objException);
            }
        } catch (Exception objException) {
            System.debug('Exception --> ' + objException);
        }
    }

    
}