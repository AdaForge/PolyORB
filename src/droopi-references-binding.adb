--  Object references (binding operation).

--  $Id$

package body Droopi.References.Binding is

   function Bind
     (R         : Ref;
      Local_ORB : ORB.ORB_Access)
     return Objects.Servant_Access is
   begin
      if Is_Nil (R) then
         raise Invalid_Reference;
      end if;

      declare
         use Binding_Data;
         use Profile_Seqs;

         Profiles : constant Element_Array
           := To_Element_Array (R.Profiles);

         Best_Preference : Profile_Preference
           := Profile_Preference'First;
         Best_Profile_Index : Integer := Profiles'Last + 1;
      begin
         for I in Profiles'Range loop
            declare
               P : constant Profile_Preference
                 := Get_Profile_Preference (Profiles (I).all);
            begin
               if P > Best_Preference then
                  Best_Preference := P;
                  Best_Profile_Index := I;
               end if;
            end;
         end loop;

         if Best_Profile_Index > Profiles'Last
           or else Best_Preference = Profile_Preference'First
         then
            raise Invalid_Reference;
            --  No supported profile found.
         end if;

         declare
            P : Profile_Type
              renames Profiles (Best_Profile_Index).all;

            --  XXX not referenced.
            pragma Warnings (Off, P);
         begin
            null;
            --  XXX implement!
            --  Actually more should be done here:
            --  * if Local_Profile: OK, the requested
            --    object statically exists.
            --  * a Local_Profile may not have a servant
            --    (if the servant needs to be incarnated).
            --    In that case, resolve the local Oid wrt
            --    the local object adapter, possibly incarnate,
            --    and return the object provided by the OA.
            --  * else if there is a network profile that
            --    designates a local TSAP: resolve the object
            --    likewise
            --  * else establish a session.

            --  ==> When binding a local reference, an OA
            --      is needed. Where do we obtain it from?
            --      Droopi.References cannot depend on Obj_Adapters!
            --      ... but D.R.Binding can depend on anything.
            --      We also need to know what profiles are local,
            --      presumably by sending the ORB an Is_Local_Profile
            --      query for each profile.

         --  if P in Local_Profile then
         --     return Local_Profile (P).Object;
         --  else
         --     S := Find_Session (P.Address);
         --     return Make_Surrogate (S);
         --  end if;
         end;

         --  XXX TODO!
         raise Not_Implemented;
         pragma Warnings (Off, Bind);
         --  XXX return not reached.
         return null;
         --  XXX keep the compiler happy.
      end;
   end Bind;

end Droopi.References.Binding;
