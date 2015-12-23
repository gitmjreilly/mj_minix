""" Scheduler """

class __scheduled_event_record__(object):
    def __init__(self, scheduled_time, event_method, name):
        self.time = scheduled_time
        self.event_method = event_method
        self.name = name
    

class Scheduler(object):

    def __init__(self):
        print "Initializing the scheduler"
        p = __scheduled_event_record__(-1, None, "Head of schedule - no event")
        r = __scheduled_event_record__(200000000000, None, "Tail of schedule - no event")
        p.next = r
        r.next = None
        self.time = 0
                
        self.__scheduled_event_list__ = p

    def add_event(self, event_method, scheduled_delta_time, name_of_event = ""):
        scheduled_time = self.time + scheduled_delta_time
        p = self.__scheduled_event_list__
        while (scheduled_time > p.next.time) :
            p = p.next

        # print "DEBUG adding scheduled event name [%s] time : %d" % (name_of_event, scheduled_time)
        r = __scheduled_event_record__(scheduled_time, event_method, name_of_event)
        r.next = p.next
        p.next = r

    def do_scheduled_events(self, time):
        p = self.__scheduled_event_list__
        if (p.next.time == time):
            pass
            # print "DEBUG - Doing events scheduled at time : %d" % time
        else:
            return
        while (True) :
            p = self.__scheduled_event_list__
            if (p.next.time == time):
                m = p.next.event_method
                # print "Running %s at %d" % (p.next.name, time)
                p.next = p.next.next
            
                # TODO run method m()
                m()
            else:
                break
                
    def set_time(self, time):
        self.time = time
 
        
    def __str__(self):
        p = self.__scheduled_event_list__
        tmp = ""
        while (p != None) :
            tmp +=  "event name : %25s scheduled time %d\n" % (p.name, p.time)
            p = p.next
            
        return(tmp)
