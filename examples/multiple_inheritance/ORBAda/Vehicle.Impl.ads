-- ==================================================== --
-- ===  Code automatically generated by IDL to Ada  === --
-- ===  compiler OrbAda-idl2ada                     === --
-- ===  Copyright Top Graph'X  1997                 === --
-- ==================================================== --
with Corba.Boa ;
with Corba.Interfacedef ;
with Corba.Implementationdef ;
package Vehicle.Impl is
   type Object is new Corba.Boa.Object_Impl with private;
   type Object_Ptr is access all Object'class;

   procedure Initialize (Oa : in Corba.Boa.Object);

   function mark_Of
      (Self : access Object) return Corba.String;

   procedure Set_mark
      (Self : access Object;
       To : in Corba.String);

   function can_drive
      ( Self : access Object;
        age : in Corba.Unsigned_Short)
         return Corba.Boolean ;

   Tgx_Implementation : Corba.Implementationdef.Ref ;
   Tgx_Interface      : Corba.Interfacedef.Ref ;
   Tgx_Oa             : Corba.Boa.Object ;
private
   type Object is new Corba.Boa.Object_Impl with
   record
      mark : Corba.String;
   end record;
end Vehicle.Impl;

