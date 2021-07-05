public class CloneMultipleParentRecordsInvocable {
	
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