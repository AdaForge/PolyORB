--  A stream type suitable for generation of Ada source code.
--  $Id: //depot/adabroker/main/idlac/ada_be-source_streams.ads#1 $

with Ada.Unchecked_Deallocation;
with Ada.Finalization;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Ada_BE.Source_Streams is

   Indent_Size : constant := 3;

   type Compilation_Unit is private;
   --  A complete compilation unit.

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

   procedure Add_With (Unit   : in out Compilation_Unit;
                       Dep    : String;
                       Use_It : Boolean := False);
   --  Add Dep to the semantic dependecies of Unit,
   --  if it is not already present. If Use_It is true,
   --  a "use" clause will be added for that unit.

   type String_Ptr is access String;
   procedure Free is
      new Ada.Unchecked_Deallocation (String, String_Ptr);

   type Unit_Kind is
     (Unit_Spec, Unit_Body);

   function New_Package
     (Name : String;
      Kind : Unit_Kind)
     return Compilation_Unit;
   --  Prepare to generate a new compilation unit.

   procedure Generate (Unit : Compilation_Unit);
   --  Produce the source code for Unit.

private

   type Dependency_Node;
   type Dependency is access Dependency_Node;

   type Dependency_Node is record
      Library_Unit : String_Ptr;
      Use_It : Boolean := False;
      Next : Dependency;
   end record;

   type Compilation_Unit is new Ada.Finalization.Controlled with record

      Library_Unit_Name : String_Ptr;
      Kind              : Unit_Kind;

      Context_Clause : Dependency
        := null;
      Library_Item   : Unbounded_String;
      Empty          : Boolean
        := True;
      Indent_Level   : Positive
        := 1;
      At_BOL         : Boolean := True;
      --  True if a line has just been ended, and the
      --  indentation space for the new line has not
      --  been written yet.

   end record;

   procedure Finalize (Object : in out Compilation_Unit);

end Ada_BE.Source_Streams;
