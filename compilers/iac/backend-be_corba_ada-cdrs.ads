------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--            B A C K E N D . B E _ C O R B A _ A D A . C D R S             --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--         Copyright (C) 2005-2012, Free Software Foundation, Inc.          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
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

--  This package contains routines related to the use of the SII instead of the
--  DII in the distributed application. For each operation (or attribute
--  accessor), four entities are generated :
--  1/ A record type whose fields corresponds to the operation parameters and
--     return type
--  2/ A custom subprogram that marshalls the parameters to a Buffer
--     without using the NVList
--  3/ A custom subprogram that unmarshalls the parameters from a Buffer
--     without using the NVList
--  4/ A subprogram that adds a note to the request notepad. This note contains
--     accesses to the marshalling and unmarshalling subprograms

--  The goal of the routines in this package is to avoid the use of the NVList
--  when the parameter types are known at compile time. This would
--  considerably increase the distributed application performances since the
--  NVList are used at 4 times during a request invocation :
--  1/ When the client marshalls the in/inout parameters before sending the
--     server
--  2/ When the server unmarshalls the in/inout parameters received from the
--     client
--  3/ When the server marshalls the result and the out/inout parameters
--     before sending them to the client
--  4/ When the client unmarshalls the result and the out/inout parameters
--     received from the server.

package Backend.BE_CORBA_Ada.CDRs is
   package Package_Spec is
      procedure Visit (E : Node_Id);
   end Package_Spec;

   package Package_Body is
      procedure Visit (E : Node_Id);
   end Package_Body;
end Backend.BE_CORBA_Ada.CDRs;
