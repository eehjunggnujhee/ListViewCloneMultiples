public class DynamicQueryInvocable {
	
    @invocableMethod(label='Listview Clone Multiple Records')
    public static FlowOutputParameters[] cloneRecords(FlowInputParameters[] input){
    // get sObject name
        String sObjectName = input[0].sObjectAPIName;
       	List<String> idsSet = input[0].ids;

        List<sObject> returnedQueryResults = new  List<sObject>();
        List<String> errorRecordsList = new List<String>();
        FlowOutputParameters output = new FlowOutputParameters();
        FlowOutputParameters[] outputs = new FlowOutputParameters []{};

        /* store sObject ids in a set collection */
        if(input[0].Ids.size()>0 && input[0].Ids.size()<31){
            /* use Schema class to retrieve all fields from sObject type */
            Map<String,Schema.SObjectField> objectfields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        
            String query ='SELECT ';
            for(String s: objectfields.keyset()){
                query += s + ', ';
            }
                query = query.removeEnd(', ');
                query += ' FROM '+sObjectName;
                query += ' WHERE Id IN :idsSet';
   
            output.returnedQueriedRecords = Database.query(query);

        }else if(input[0].Ids.size()>30){
            return null; // if more than 30 records are selected. the transaction stops and flow error displays
    	}else{
            return null; // if there is no selected record, exist the transaction
        }
        outputs.add(output);
        
        return outputs;
	}
        /* Input parameters from flow defined in the FlowInputParameters inner class */
    public class FlowInputParameters{
        @invocableVariable(label='Records to Clone' required = true)
        public List<String> ids;
        @invocableVariable(label='sObject API Name' required = true)
        public String sObjectAPIName;
    }
    
     /* output parameter to Flow defined in the FlowOutputParameters inner class */
    public class FlowOutputParameters{
        @InvocableVariable(label='Returned Cloned Records' required = true)
        public List<sObject> returnedQueriedRecords;
        @InvocableVariable(label='errorMessages' required = true)
        public String errorMessages;
    }
}