------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--                C O R B A . O B J E C T . P O L I C I E S                 --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2005-2012, Free Software Foundation, Inc.          --
--                                                                          --
-- This specification is derived from the CORBA Specification, and adapted  --
-- for use with PolyORB. The copyright notice above, and the license        --
-- provisions that follow apply solely to the contents neither explicitly   --
-- nor implicitly specified by the CORBA Specification defined by the OMG.  --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                  PolyORB is maintained by AdaCore                        --
--                     (email: sales@adacore.com)                           --
--                                                                          --
------------------------------------------------------------------------------

with CORBA.DomainManager;
with CORBA.Policy;

package CORBA.Object.Policies is

   function Get_Policy
     (Self        : Ref;
      Policy_Type : PolicyType)
      return CORBA.Policy.Ref;

   function Get_Domain_Managers
     (Self : Ref'Class)
      return CORBA.DomainManager.DomainManagersList;

   procedure Set_Policy_Overrides
     (Self     : Ref'Class;
      Policies : CORBA.Policy.PolicyList;
      Set_Add  : SetOverrideType);

   function Get_Client_Policy
     (Self     : Ref'Class;
      The_Type : PolicyType)
      return CORBA.Policy.Ref;

   function Get_Policy_Overrides
     (Self  : Ref'Class;
      Types : CORBA.Policy.PolicyTypeSeq)
      return CORBA.Policy.PolicyList;

   procedure Validate_Connection
     (Self                  : Ref;
      Inconsistent_Policies :    out CORBA.Policy.PolicyList;
      Result                :    out CORBA.Boolean);
   --  Implementation Notes:
   --  * Inconsistent_Policies is currently not set.
   --  * The actual processing of the LocateRequest message depends on
   --  the configuration of the GIOP personality, if it is used.

end CORBA.Object.Policies;
