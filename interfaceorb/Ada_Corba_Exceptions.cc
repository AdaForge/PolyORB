//--------------------------------------------------------------------------//
//                                                                          //
//                          ADABROKER COMPONENTS                            //
//                                                                          //
//                            A D A B R O K E R                             //
//                                                                          //
//                            $Revision: 1.8 $
//                                                                          //
//         Copyright (C) 1999-2000 ENST Paris University, France.           //
//                                                                          //
// AdaBroker is free software; you  can  redistribute  it and/or modify it  //
// under terms of the  GNU General Public License as published by the  Free //
// Software Foundation;  either version 2,  or (at your option)  any  later //
// version. AdaBroker  is distributed  in the hope that it will be  useful, //
// but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- //
// TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public //
// License  for more details.  You should have received  a copy of the GNU  //
// General Public License distributed with AdaBroker; see file COPYING. If  //
// not, write to the Free Software Foundation, 59 Temple Place - Suite 330, //
// Boston, MA 02111-1307, USA.                                              //
//                                                                          //
// As a special exception,  if other files  instantiate  generics from this //
// unit, or you link  this unit with other files  to produce an executable, //
// this  unit  does not  by itself cause  the resulting  executable  to  be //
// covered  by the  GNU  General  Public  License.  This exception does not //
// however invalidate  any other reasons why  the executable file  might be //
// covered by the  GNU Public License.                                      //
//                                                                          //
//             AdaBroker is maintained by ENST Paris University.            //
//                     (email: broker@inf.enst.fr)                          //
//                                                                          //
//--------------------------------------------------------------------------//
#include "Ada_Corba_Exceptions.hh"
#include "Ada_exceptions.hh"

CORBA::Boolean
_omni_callTransientExceptionHandler(Ada_OmniObject* omniobj,
				    CORBA::ULong retries,
				    CORBA::ULong minor,
				    CORBA::CompletionStatus status)
{
  ADABROKER_TRY

    // Create an exception object.
    CORBA::TRANSIENT ex (minor, status);

    // Throw it.
    return _omni_callTransientExceptionHandler (omniobj->CPP_Object,
					        retries,
					        ex);
  ADABROKER_CATCH

    // Never reach this code. Just a default return for dummy
    // compilers.
    CORBA::Boolean default_result = false;
    return default_result;
}

CORBA::Boolean
_omni_callCommFailureExceptionHandler(Ada_OmniObject* omniobj,
				      CORBA::ULong retries,
				      CORBA::ULong minor,
				      CORBA::CompletionStatus status)
{
  ADABROKER_TRY

    // Create an exception object.
    CORBA::COMM_FAILURE ex (minor, status);

    // Throw it.
    return _omni_callCommFailureExceptionHandler (omniobj->CPP_Object,
						  retries,
						  ex);
  ADABROKER_CATCH

    // Never reach this. Just a default return for dummy compilers.
    CORBA::Boolean default_result = false;
    return default_result; 
}

CORBA::Boolean
_omni_callSystemExceptionHandler(Ada_OmniObject* omniobj,
				 CORBA::ULong retries,
				 CORBA::ULong minor,
				 CORBA::CompletionStatus status)
{
  ADABROKER_TRY

    // Create an exception object.
    CORBA::SystemException ex (minor, status);

    // Throw it.
    return _omni_callSystemExceptionHandler (omniobj->CPP_Object,
					     retries,
					     ex);
  ADABROKER_CATCH

    // Never reach this code. Just a default return for dummy
    // compilers.
    CORBA::Boolean default_result = false;
    return default_result; 
}

