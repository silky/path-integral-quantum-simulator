# class Initiator(object):
#     pass
# 


class AmpFinder(object):
    
    _count = 0 # count of the number of AmpFinders (class global, use the getter/setters)
    _list = []
    type = "FINDAMP"
    
    @property
    def count(self):
        return type(self)._count

    @count.setter
    def count(self,val):
        type(self)._count = val
        
    def addself(self):
        type(self)._list.append(self)
        
    type = "FINDAMP"
    def __init__(self, depth, down_connection):
        self.depth = depth
        self.down_connection = down_connection
        
        self.idx = self.count
        self.count += 1
        self.addself()
    
    def __str__(self):
        return "{},{},{}".format( self.depth, self.down_connection.type, self.down_connection.idx )


class HeightDiv(object):
    
    _count = 0 # count of the number of AmpFinders (class global, use the getter/setters)
    _list = []
    type = "HEIGHTDIV"
    
    @property
    def count(self):
        return type(self)._count

    @count.setter
    def count(self,val):
        type(self)._count = val
    
    def addself(self):
        type(self)._list.append(self)

    def __init__(self, left_down_conn, right_down_conn):
        self.left = left_down_conn
        self.right = right_down_conn
        assert(left_down_conn.type == right_down_conn.type)
        
        self.idx = self.count
        self.count += 1
        self.addself()
        
    def __str__(self):
        return "{},{},{}".format( self.left.type, self.left.idx, self.right.idx )


class Base(object):
    
    _count = 0 # count of the number of AmpFinders (class global, use the getter/setters)
    type = "BASE"
    
    @property
    def count(self):
        return type(self)._count

    @count.setter
    def count(self,val):
        type(self)._count = val
    

    def __init__(self):        
        self.idx = self.count
        self.count += 1


# 
# class HeightDiv(object):
#     pass
# 
# class Base(object):
#     pass

spec = AmpFinder(5, 
            AmpFinder(3, 
                HeightDiv(
                    AmpFinder(0, Base()), 
                    AmpFinder(0, Base())
                    )
                )
        )

config = "\n".join(["{}\n{}\n{}".format(AmpFinder._count, HeightDiv._count, Base._count)] + [str(amp) for amp in AmpFinder._list] + [str(div) for div in HeightDiv._list])

print(config)
