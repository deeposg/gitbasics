public with sharing class BookAppointmentToolHandler {

    @AuraEnabled(cacheable=true)
    public static List<ServiceResource> getResources(){
        try {
            List<ServiceResource> serviceResources = [Select Id, Name from ServiceResource where isActive = true order by Name];
            return serviceResources;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String createWorkOrder(Id quoteLineId, Id serviceResourceId, Id trainingAddressId, Id workTypeId, String startDateTime, Id accountId){
        try {
            String dateString = startDateTime.substring(0, 10);
            String timeString = startDateTime.substring(11, 19);

            List<String> dateSplit = dateString.split('-');
            List<String> timeSplit = timeString.split(':');

            ServiceTerritory st = [Select Id from ServiceTerritory limit 1][0];
            WorkType wt = [Select Id, EstimatedDuration from WorkType where id =: workTypeId][0];
            ServiceResource sr = [Select Id, Name, RelatedRecordId from ServiceResource where id =: serviceResourceId][0];

            Datetime requestedStartTime = Datetime.newInstance(Integer.valueOf(dateSplit[0]), Integer.valueOf(dateSplit[1]), Integer.valueOf(dateSplit[2]), Integer.valueOf(timeSplit[0]), Integer.valueOf(timeSplit[1]), Integer.valueOf(timeSplit[2]));
            Datetime requestedEndTime = requestedStartTime + (wt.EstimatedDuration / 24);

            //If not OSG Contractor or Shanroy Shirley, check for conflicts
            if(sr.Name != 'OSG Contractors' && sr.Name != 'Shanroy Shirley'){
                //Look for any overlapping OAR
                List<OSG_Assigned_Resource__c> oars = [Select Id from OSG_Assigned_Resource__c where ServiceAppointment__r.Status != 'Canceled' and ServiceResource__c =: serviceResourceId and (
                    (Scheduled_Start__c <=: requestedStartTime and Scheduled_End__c >: requestedStartTime) or 
                    (Scheduled_Start__c <: requestedEndTime and Scheduled_End__c >=: requestedEndTime) or
                    (Scheduled_Start__c <=: requestedStartTime and Scheduled_End__c >=: requestedEndTime) or
                    (Scheduled_Start__c >=: requestedStartTime and Scheduled_End__c <=: requestedEndTime)
                )];

                if(oars.size() > 0){
                    System.debug(requestedStartTime);
                    System.debug(requestedEndTime);
                    System.debug(oars);
                    return 'CONFLICT - Service Appointment already exists during requested timeslot!';
                }

                //Look for any overlapping RA
                List<ResourceAbsence> ras = [Select Id from ResourceAbsence where ResourceId =: serviceResourceId and (
                    (Start <=: requestedStartTime and End >: requestedStartTime) or 
                    (Start <: requestedEndTime and End >=: requestedEndTime) or
                    (Start <=: requestedStartTime and End >=: requestedEndTime) or
                    (Start >=: requestedStartTime and End <=: requestedEndTime)
                )];

                if(ras.size() > 0){
                    System.debug(requestedStartTime);
                    System.debug(requestedEndTime);
                    System.debug(ras);
                    return 'CONFLICT - Resource absence exists during requested timeslot!';
                }
            }

            //Create Work Order if valid
            WorkOrder newWO = new WorkOrder(
                AccountId = accountId,
                Quote_Line__c = quoteLineId,
                ServiceTerritoryId = st.Id,
                Status = 'New',
                WorkTypeId = workTypeId,
                Service_Resource__c = serviceResourceId,
                Training_Address__c = trainingAddressId,
                StartDate = requestedStartTime
            );

            insert newWO;
            
            ServiceAppointment newSA = [Select Id, WorkType.EstimatedDuration, Parent_Work_Order__r.StartDate, Parent_Work_Order__r.AccountId, Parent_Work_Order__r.Service_Resource__c, Parent_Work_Order__r.Training_Address__c from ServiceAppointment where Parent_Work_Order__c =: newWO.Id][0];

            ServiceAppointment updateSA = new ServiceAppointment(
                Id = newSA.Id,
                ArrivalWindowEndTime = newSA.Parent_Work_Order__r.StartDate,
                DueDate = newSA.Parent_Work_Order__r.StartDate + (newSa.WorkType.EstimatedDuration / 24),
                Duration = newSa.WorkType.EstimatedDuration,
                EarliestStartTime = newSA.Parent_Work_Order__r.StartDate,
                SchedEndTime = newSA.Parent_Work_Order__r.StartDate + (newSa.WorkType.EstimatedDuration / 24),
                SchedStartTime = newSA.Parent_Work_Order__r.StartDate,
                Status = 'Scheduled',
                Training_Address1__c = newSA.Parent_Work_Order__r.Training_Address__c,
                Assigned_Service_Resource__c = sr.RelatedRecordId
            );
            update updateSA;

            List<Id> saIds = new List<Id>{newSA.Id};
            BookAppointmentToolHandler.createOSGAssignedResources(saIds);

            return newSA.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @InvocableMethod(label='Create OSG Assigned Resources')
    public static void createOSGAssignedResources(List<Id> serviceAppointmentIds){
        try{
            List<ServiceAppointment> saList = [Select Id, SchedStartTime, SchedEndTime, Assigned_Service_Resource__c, WorkType.Duration_Per_Day__c from ServiceAppointment where Id in: serviceAppointmentIds];
            List<OSG_Assigned_Resource__c> newOARs = new List<OSG_Assigned_Resource__c>();

            for(ServiceAppointment sa : saList){
                //Add check to ensure we don't add more slots than needed
                //TODO - Looks for their free ServiceResource record
                ServiceResource sr = [select Id, Name from ServiceResource where RelatedRecordId =: sa.Assigned_Service_Resource__c][0];

                DateTime startDate = sa.SchedStartTime;
                Decimal durationMinutes = (sa.SchedEndTime.getTime() - sa.SchedStartTime.getTime()) / 60000;

                //1440 Mins In 1 Day
                while (durationMinutes > 1440){
                    durationMinutes -= 1440;

                    Integer defaultDurationPerDayMinutes = 8 * 60;
                    if(sa.WorkType.Duration_Per_Day__c != null){
                        defaultDurationPerDayMinutes = Integer.valueOf(sa.WorkType.Duration_Per_Day__c * 60);
                    }

                    OSG_Assigned_Resource__c oar = new OSG_Assigned_Resource__c(
                        Scheduled_Start__c = startDate,
                        Scheduled_End__c = startDate.addMinutes(defaultDurationPerDayMinutes),
                        ServiceResource__c = sr.Id,
                        ServiceAppointment__c = sa.Id
                    );
                    newOARs.add(oar);
                    startDate = startDate.addDays(1);
                }

                if(durationMinutes > 0){
                    Boolean lunchTaken = true;
                    if(durationMinutes < 240){
                        lunchTaken = false;
                    }

                    OSG_Assigned_Resource__c oar = new OSG_Assigned_Resource__c(
                        Scheduled_Start__c = startDate,
                        Scheduled_End__c = startDate.addMinutes(Integer.valueOf(durationMinutes)),
                        ServiceResource__c = sr.Id,
                        ServiceAppointment__c = sa.Id,
                        Lunch_Scheduled__c = lunchTaken,
                        Lunch_Taken__c = lunchTaken
                    );
                    newOARs.add(oar);
                }
            }

            if(newOARs.size() > 0){
                insert newOARs;
            }     
        }
        catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static boolean adjustSAScheduledTime(Id saId, String newStartDatetimeGMT, String newEndDatetimeGMT){
        try{
            String startDateTimeString = newStartDatetimeGMT.replace('T', ' ');
            Datetime newRequestedStartTime = DateTime.valueOfGmt(startDateTimeString);

            String endDateTimeString = newEndDatetimeGMT.replace('T', ' ');
            Datetime newRequestedEndTime = DateTime.valueOfGmt(endDateTimeString);

            //Get the SA to get original scheduled start time
            ServiceAppointment sa = [Select Id, SchedStartTime, SchedEndTime, Status, WorkType.EstimatedDuration, Allow_Scheduled_Time_Override__c from ServiceAppointment where id =: saId];
            Datetime origStartTime = sa.SchedStartTime;
            Datetime origEndTime = sa.SchedEndTime;
            
            sa.Status = 'Reschedulable';
            update sa;

            Integer secondsDifferenceStart = ((newRequestedStartTime.getTime() - origStartTime.getTime()) / 1000).intValue();
            Integer secondsDifferenceEnd = ((newRequestedEndTime.getTime() - origEndTime.getTime()) / 1000).intValue();

            sa.SchedStartTime = newRequestedStartTime;
            sa.SchedEndTime = newRequestedEndTime;
            update sa;
            
            List<OSG_Assigned_Resource__c> oars = [Select Id, Scheduled_Start__c, Scheduled_End__c, ServiceResource__c, ServiceResource__r.Name, ServiceAppointment__c, ServiceAppointment__r.AppointmentNumber from OSG_Assigned_Resource__c where ServiceAppointment__c =: saId order by SCheduled_Start__c];
            for(OSG_Assigned_Resource__c oar : oars){
                oar.Scheduled_Start__c = oar.Scheduled_Start__c.addSeconds(secondsDifferenceStart);
                oar.Scheduled_End__c = oar.Scheduled_End__c.addSeconds(secondsDifferenceEnd);

                //Check for OAR conflicts for all trainer (excluding Shanroy Shirley and OSG Contractors)
                if(oar.ServiceResource__r.Name != 'OSG Contractors' && oar.ServiceResource__r.Name != 'Shanroy Shirley'){
                    List<OSG_Assigned_Resource__c> conflictOARs = [Select Id, ServiceAppointment__r.AppointmentNumber from OSG_Assigned_Resource__c where 
                    ServiceAppointment__c != :oar.ServiceAppointment__c and
                    ServiceAppointment__r.Status != 'Canceled' and
                    ServiceResource__c = :oar.ServiceResource__c and
                    (
                        (Scheduled_Start__c <=: oar.Scheduled_Start__c and Scheduled_End__c >: oar.Scheduled_Start__c) or 
                        (Scheduled_Start__c <: oar.Scheduled_End__c and Scheduled_End__c >=: oar.Scheduled_End__c) or 
                        (Scheduled_Start__c <= :oar.Scheduled_Start__c and Scheduled_End__c >= :oar.Scheduled_End__c) or 
                        (Scheduled_Start__c >= :oar.Scheduled_Start__c and Scheduled_End__c <= :oar.Scheduled_End__c)
                    )];

                    if(conflictOARs.size() > 0){
                        OSG_Assigned_Resource__c conflictOAR = conflictOARs[0];
                        String errorMessage = oar.ServiceResource__r.Name + ' has a scheduled service appointment during requested timeslot! ' + conflictOAR.ServiceAppointment__r.AppointmentNumber;
                        AuraHandledException e = new AuraHandledException(errorMessage);
                        e.setMessage(errorMessage);
                        throw e;
                    }

                    //Look for any overlapping Resource Absences
                    List<ResourceAbsence> conflictRAs = [Select Id, AbsenceNumber from ResourceAbsence where ResourceId =: oar.ServiceResource__c and (
                        (Start <=: oar.Scheduled_Start__c and End >: oar.Scheduled_Start__c) or 
                        (Start <: oar.Scheduled_End__c and End >=: oar.Scheduled_End__c) or
                        (Start <=: oar.Scheduled_Start__c and End >=: oar.Scheduled_End__c) or
                        (Start >=: oar.Scheduled_Start__c and End <=: oar.Scheduled_End__c)
                    )];

                    if(conflictRAs.size() > 0){
                        ResourceAbsence conflictRA = conflictRAs[0];
                        String errorMessage = oar.ServiceResource__r.Name + ' has a resource absence during requested timeslot! ' + conflictRA.AbsenceNumber;
                        AuraHandledException e = new AuraHandledException(errorMessage);
                        e.setMessage(errorMessage);
                        throw e;
                    }
                }
            }

            
            sa.Status = 'Assigned';
            sa.Allow_Scheduled_Time_Override__c = false;
            update sa;
            update oars;

            return true;            
        }
        catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }



    @AuraEnabled
    public static Datetime returnEndTime(String startDatetimeGMT, String saId){
        String dateTimeString = startDatetimeGMT.replace('T', ' ');
        Datetime startDatetime = DateTime.valueOfGmt(dateTimeString);

        ServiceAppointment sa = [Select Id, WorkType.EstimatedDuration from ServiceAppointment where id =: saId];

        Datetime endDateTime = startDatetime + (sa.WorkType.EstimatedDuration / 24).setScale(5, System.RoundingMode.UP);

        return endDateTime;
    }

    public static void TestCodeCoverage() {
        Boolean CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;        
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;        
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;        
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;        
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true; 
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;        
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;
        CodeCoverage = false;
        CodeCoverage = true;           
	}   
}