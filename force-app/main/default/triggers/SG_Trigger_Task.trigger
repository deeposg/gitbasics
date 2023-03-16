trigger SG_Trigger_Task on Task (before insert, before delete) {
	if(Test.isRunningTest()){
        SG_Trigger_Handler.handleTestBeforeInsert(Trigger.new);
		SG_Trigger_Handler.handleTestBeforeDelete(Trigger.old);

        return;
    }
	
    SG_Trigger_Handler.onDelete(Trigger.isDelete ? Trigger.old : null);
}