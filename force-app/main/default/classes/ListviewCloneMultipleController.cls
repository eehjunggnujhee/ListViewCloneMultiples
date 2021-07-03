/*
 * 	Class Name: ListviewCloneMultipleController
 * 	The class describes a dynamic constructor to support standard and custom objects StandardSetController.
 * 	The getter and setter sObject type for the list set should match with the standardcontroller defined in a visualforce page.
 *	This example shows Application__c custom object.
 * 
*/
public class ListviewCloneMultipleController {
   	public List<Application__c> ListSelectedRecords { // this is the only line you need to update List<Application__c>
       get;	
       set;
    }
    
    /*
     * 
     * 
     * 
	*/
    public ListviewCloneMultipleController (ApexPages.StandardSetController listcontroller){
       	List<sObject> selectedRecords =  listcontroller.getSelected();
        Set < Id > selectedRecordIds = new Set < Id >();

        // get sObject name
        String sObjectName = selectedRecords[0].getSObjectType().getDescribe().getName();

        /* store sObject ids in a set collection */
        if(listController.getResultSize()>0 && listController.getResultSize()<31){
            for(sObject obj : selectedRecords){
                selectedRecordIds.add((Id)obj.get('id'));
            }
        }else if(listController.getResultSize()>30){
            return; // if more than 30 records are selected. the transaction stops and flow error displays
    	}else{
            return; // if there is no selected record, exist the transaction
        }
        
        /* use Schema class to retrieve all fields from sObject type */
        Map<String,Schema.SObjectField> objectfields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        
        String query ='SELECT ';
        for(String s: objectfields.keyset()){
            query += s + ', ';
        }
            query = query.removeEnd(', ');
            query += ' FROM '+sObjectName;
            query += ' WHERE Id IN :selectedRecordIds';
        
        ListSelectedRecords = Database.query(query); // Getter
    }
    
    /*
     * 
     * 
     * 
	*/
    @invocableMethod(label='Listview Clone Multiple Records')
    public static FlowOutputParameters[] cloneRecords(FlowInputParameters[] input){
        /* set variables null */
        List<sObject> insertsObjects = new List<sObject>(); 
        List<sObject> outputObjects = new List<sObject>();
        List<String> errorRecordsList = new List<String>();
        FlowOutputParameters output = new FlowOutputParameters();
        FlowOutputParameters[] outputs = new FlowOutputParameters []{};
            
        String errorMessages ='';
        List<sObject> items = new FlowOutputParameters().clonedsObjectRecords;
        
            if(input.size() <31){
                for(sObject o : input[0].recordsToClone){
                    sObject obj = o.clone(false);
                    insertsObjects.add(obj);
                }
            
            Database.SaveResult[] result = Database.Insert(insertsObjects,false);

                Integer indexSubtract = result.size();
                for(Integer i=0;i<result.size();i++){
                    if(!result[i].isSuccess()){
                        for(Database.Error err : result[i].getErrors()){
                            errorMessages += '\nThe following error has occurred: '
                                        +	'\n'+err.getStatusCode() + ': '+err.getMessage()
                                        +	'\nImpacted Fields: '+err.getFields()
                            			+	'\nCloned from record Id: '+input[0].recordsToClone[i].get('id')
                                		+	'\n\n';
 
                            errorRecordsList.add((string)input[0].recordsToClone[i].get('id'));
                        }
                    }else{
                        outputObjects.add(insertsObjects[i]); // output only successfully cloned records data
                    }
                }
            }else{
                errorMessages +='\nToo many records are selected';
            }
        /* build out output object */
        output.clonedsObjectRecords = outputObjects;
        output.errorMessages = errorMessages;
        output.errorRecords = errorRecordsList;
        
        outputs.add(output);
       
        return outputs;    
    }
    
    /* Input parameters from flow defined in the FlowInputParameters inner class */
    public class FlowInputParameters{
        @invocableVariable(label='Records to Clone' required = true)
        public List<sObject> recordsToClone;
    }
    
     /* output parameter to Flow defined in the FlowOutputParameters inner class */
    public class FlowOutputParameters{
        @InvocableVariable(label='Returned Cloned Records' required = true)
        public List<sObject> clonedsObjectRecords;
        @InvocableVariable(label='errorMessages' required = true)
        public String errorMessages;
        @InvocableVariable(label='errorRecords' required = true)
        public List<String> errorRecords;
    }
}