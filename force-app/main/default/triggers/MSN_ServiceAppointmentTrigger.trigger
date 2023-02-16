/**
 * @File Name          : MSN_ServiceAppointmentTrigger.cls
 * @Description        : Trigger for ServiceAppointment
 * @Author             : David Azzi
 * @Group              : 
 * @Last Modified By   : David Azzi
 * @Last Modified On   : 01/12/2021
 * @Modification Log   : 
 * Ver      Date            Author                  Modification
 * 1.0      01/12/2021      David Azzi              Initial Version
**/
trigger MSN_ServiceAppointmentTrigger on ServiceAppointment (before insert, before update, before delete, 
                                            after insert, after update, after delete, 
                                            after undelete) 
{

    TriggerDispatcher.Run(new MSN_ServiceAppointmentTriggerHandler());
}