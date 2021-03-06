------------------------------------------------------------------------------
--                                                                          --
--                           POLYORB COMPONENTS                             --
--                                                                          --
--            P O L Y O R B . T R A N S P O R T . S O C K E T S             --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--           Copyright (C) 2013, Free Software Foundation, Inc.             --
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

pragma Ada_2012;

--  Shared code for datagram and connected socket-based transports

with PolyORB.Sockets;
with PolyORB.Utils.Sockets;

package PolyORB.Transport.Sockets is

   use PolyORB.Sockets;
   use PolyORB.Utils.Sockets;

   type Socket_Access_Point is limited interface;

   procedure Set_Socket_AP_Publish_Name
      (SAP  : in out Socket_Access_Point;
       Name : Socket_Name) is abstract;
   function Socket_AP_Publish_Name
      (SAP : access Socket_Access_Point) return Socket_Name is abstract;

   function Socket_AP_Address
     (SAP : Socket_Access_Point) return Sock_Addr_Type is abstract;

   function Socket_AP_Address
     (SAP : Socket_Access_Point'Class) return Socket_Name;
   --  Address of SAP, for debugging purposes

end PolyORB.Transport.Sockets;
