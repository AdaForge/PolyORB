----------------------------------------
--                                    --
--       ----  ---     --  ----       --
--       -      -     - -  -  -       --
--       -      -    ----  -  -       --
--       ----  ---  -   -  ----       --
--                                    --
----------------------------------------
--  CORBA                             --
--  Interface for                     --
--  Ada'95 distributed systems annex  --
--  Objects                           --
----------------------------------------
--  Copyright (c) 1999                --
--  Icole nationale supirieure des    --
--  tilicommunications                --
----------------------------------------

--  An abstraction for the production of the text of
--  an Ada 95 compilation unit.
--  $Id: //depot/ciao/main/ciao-ada_source_streams.ads#3 $

with Ada.Finalization;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package CIAO.Ada_Source_Streams is

   Indent_Size : constant := 3;

   type Compilation_Unit is private;
   --  A complete compilation unit.

   type Unit_Kind is
     (Unit_Spec, Unit_Body);
   --  The kind of a compilation unit.

   type Diversion is
     (Visible_Declarations,
      Private_Declarations,
      Generic_Formals,
      Elaboration);
   --  A compilation unit can have several diversions,
   --  each of which is a linear stream of source code
   --  lines.
   --  The Visible_Declarations and Private_Declarations
   --  diversions correspond to the visible and private
   --  parts of the compilation unit's declarative region.
   --  The Elaboration diversion corresponds to the elaboration
   --  statements in a package body.

   type Elab_Control_Pragma is
     (None,           --  Add no elaboration control pragma
      Elaborate,      --  Add a pragma Elaborate
      Elaborate_All); --  Add a pragma Elaborate_All
   --  Possible elaboration control pragmas that can be added
   --  for a dependency.

   ---------------------------------------------------
   -- The following subprograms operate globally on --
   -- a compilation unit.                           --
   ---------------------------------------------------

   procedure Divert
     (CU     : in out Compilation_Unit;
      Whence : Diversion);
   --  Set CU's current diversion to Whence.
   --  If CU is a Unit_Spec, it is not allowed to set the current
   --  diversion to Elaboration.
   --  If CU is a Unit_Body, it is not allowed to set the current
   --  diversion to Private_Declarations or Generic_Formals.

   procedure Add_With (Unit      : in out Compilation_Unit;
                       Dep       : String;
                       Use_It    : Boolean := False;
                       Elab_Control : Elab_Control_Pragma := None);
   --  Add Dep to the semantic dependecies of Unit,
   --  if it is not already present. If Use_It is true,
   --  a "use" clause will be added for that unit.
   --  Additionnally, an elaboration control pragma may
   --  be inserted according to Elab_Control.

   procedure Add_Elaborate_Body (Unit : in out Compilation_Unit);
   --  Add a pragma Elaborate_Body to the spec denoted by Unit.

   procedure Suppress_Warning_Message (Unit : in out Compilation_Unit);
   --  Remove warning such as "Do not modify this file". Used for
   --  implementations.

   function New_Package
     (Name : String;
      Kind : Unit_Kind)
     return Compilation_Unit;
   --  Prepare to generate a new compilation unit.

   procedure Generate
     (Unit : Compilation_Unit;
      Is_Generic_Instanciation : Boolean := False;
      To_Stdout : Boolean := False);
   --  Produce the source code for Unit.
   --  If Is_Generic_Instanciation, then Unit's Kind must
   --  be Unit_Spec, and Unit must be a library-level
   --  instanciation of a generic package.
   --  If To_Stdout, the code is emitted to standard output.

   ----------------------------------------------------------------
   -- The following subprograms operate on the current diversion --
   ----------------------------------------------------------------

   procedure Set_Empty (Unit : in out Compilation_Unit);
   --  Set the Empty flag on the compilation unit.
   pragma Inline (Set_Empty);

   procedure Put
     (Unit : in out Compilation_Unit;
      Text : String);
   --  Append a text fragment to a compilation unit.

   procedure Put_Line
     (Unit : in out Compilation_Unit;
      Line : String);
   --  Append a whole line to a compilation unit.

   procedure New_Line (Unit : in out Compilation_Unit);
   --  Append a blank line to a compilation unit, or
   --  terminate an unfinished line.

   procedure Inc_Indent (Unit : in out Compilation_Unit);
   procedure Dec_Indent (Unit : in out Compilation_Unit);
   --  Increment or decrement the indentation level
   --  for the compilation unit.

private

   type String_Ptr is access String;

   type Dependency_Node;
   type Dependency is access Dependency_Node;

   type Diversion_Data is record
      Library_Item   : Unbounded_String;
      Empty          : Boolean
        := True;
      Indent_Level   : Positive := 1;
      At_BOL         : Boolean := True;
      --  True if a line has just been ended, and the
      --  indentation space for the new line has not
      --  been written yet.
   end record;

   type Diversion_Set is array (Diversion) of aliased Diversion_Data;

   type Compilation_Unit is new Ada.Finalization.Controlled with record

      Library_Unit_Name : String_Ptr;
      Kind              : Unit_Kind;
      Elaborate_Body    : Boolean    := False;
      No_Warning        : Boolean    := False;

      Context_Clause    : Dependency := null;

      Current_Diversion : Diversion  := Visible_Declarations;

      Diversions        : Diversion_Set;
   end record;

   procedure Finalize (Object : in out Compilation_Unit);

end CIAO.Ada_Source_Streams;