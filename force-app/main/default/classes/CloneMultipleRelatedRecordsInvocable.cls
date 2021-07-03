public class CloneMultipleRelatedRecordsInvocable { //cloneRelatedRecord
	@invocableMethod(label='Clone Multiple Related Records')
    public static FlowOutputParameters[] returnQuriedResult(FlowInputParameters[] input){
        
        Map<Id,Id> oldNewIdMap = new Map<Id,Id>(); // stores key:value pair to match new id based on the old id

        for(integer i=0;i<input[0].recordsQuery.size();i++){
            oldNewIdMap.put((id)input[0].recordsQuery[i].get('id'),(id)input[0].recordsCloned[i].get('id'));
        }
        
        /* get sObjectfield from Schema class to build the query */
        Map<String,Schema.SObjectField> objectfields = Schema.getGlobalDescribe().get(input[0].sObjectName).getDescribe().fields.getMap();

		Set<id> keySet = new Set<id>(oldNewIdMap.keyset()); // stores old Ids for database query
        
        String query ='SELECT ';
        for(String s: objectfields.keyset()){
            query += s + ', ';
        }
            query = query.removeEnd(', ');
            query += ' FROM '+input[0].sObjectName;
            query += ' WHERE ';
            query += input[0].lookupFieldAIPName+ ' IN :keySet';
        
        List<sObject> queryResults = new List<sObject>(Database.query(query));
        
        /* update cloned records */
        List<sObject> insertsObjects = new List<sObject>();
        
        FlowOutputParameters output = new FlowOutputParameters();
        FlowOutputParameters[] outputs = new FlowOutputParameters []{};
            
        String errorMessages ='';
        if(queryResults.size() >0){
            for(sObject o : queryResults){
                sObject obj = o.clone(false);
                if(oldNewIdMap.get((id)obj.get(input[0].lookupFieldAIPName))!=null){
                    obj.put(input[0].lookupFieldAIPName,oldNewIdMap.get((id)obj.get(input[0].lookupFieldAIPName)));
                    system.debug('obj: '+obj.get(input[0].lookupFieldAIPName));
                    system.debug('obj: '+obj);
                    insertsObjects.add(obj);
                    system.debug('obj size: '+insertsObjects.size());
                }else{
                    errorMessages +='\nThere is no reference record to clone';
                }
            }
            Database.SaveResult[] result = Database.Insert(insertsObjects,false);
            
            for(Database.SaveResult r : result){
             if(!r.isSuccess()){
                  for(Database.Error err : r.getErrors()){
                        errorMessages += '\n\n'+input[0].lookupFieldAIPName+' The following error has occurred: '
                            		+	'\n'+err.getStatusCode() + ': '+err.getMessage()
                            		+	'\nRecordId: '+r.getId()
                            		+	'\nImpacted Fields: '+err.getFields();              				
                    }
                }
        	}

        }else{
               errorMessages +='\nThere is no reference record to clone from';
        }
		/* build the output object */
        output.returnedResult = insertsObjects;
        output.errorMessages = errorMessages;

        outputs.add(output);
       
        return outputs;
    }
    
    /* Input parameters from flow defined in the FlowInputParameters inner class */
    public class FlowInputParameters{
        @invocableVariable(label='Records to Query' required = true) // original records
        public List<sObject> recordsQuery;
        @invocableVariable(label='Cloned Records' required = true) // cloned records
        public List<sObject> recordsCloned;
        @invocableVariable(label='sObject API Name' required = true) // for database query
        Public String sObjectName;
        @invocableVariable(label='Lookup API Name' required = true) // for getting API name of the lookup field
        Public String lookupFieldAIPName;      
    }
    
    /* output parameter to Flow defined in the FlowOutputParameters inner class */
    public class FlowOutputParameters{
        @InvocableVariable(label='Returned Results' required = true) // returned DML committed data
        public List<sObject> returnedResult;
        @InvocableVariable(label='errorMessages' required = true) // returned database errors
        public String errorMessages;
    }
}