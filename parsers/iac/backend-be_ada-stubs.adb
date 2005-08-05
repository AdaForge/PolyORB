with Namet;     use Namet;
with Types;     use Types;
with Values;    use Values;

with Frontend.Nutils;
with Frontend.Nodes;            use Frontend.Nodes;

with Backend.BE_Ada.Expand;     use Backend.BE_Ada.Expand;
with Backend.BE_Ada.IDL_To_Ada; use Backend.BE_Ada.IDL_To_Ada;
with Backend.BE_Ada.Nodes;      use Backend.BE_Ada.Nodes;
with Backend.BE_Ada.Nutils;     use Backend.BE_Ada.Nutils;
with Backend.BE_Ada.Runtime;    use Backend.BE_Ada.Runtime;

package body Backend.BE_Ada.Stubs is

   Getter : constant Character := 'G';
   Setter : constant Character := 'S';

   package FEN renames Frontend.Nodes;
   package BEN renames Backend.BE_Ada.Nodes;
   package FEU renames Frontend.Nutils;

   function Marshaller_Body
     (Subp_Spec : Node_Id) return List_Id;
   function Marshaller_Declarations
     (Subp_Spec : Node_Id) return List_Id;

   function Visible_Is_A_Spec (E : Node_Id) return Node_Id;
   function Visible_Is_A_Body (E : Node_Id) return Node_Id;

   function Local_Is_A_Spec return Node_Id;

   package body Package_Spec is

      procedure Visit_Attribute_Declaration
        (E       : Node_Id;
         Binding : Boolean := True);
      procedure Visit_Constant_Declaration (E : Node_Id);
      procedure Visit_Enumeration_Type (E : Node_Id);
      procedure Visit_Exception_Declaration (E : Node_Id);
      procedure Visit_Forward_Interface_Declaration (E : Node_Id);
      procedure Visit_Interface_Declaration (E : Node_Id);
      procedure Visit_Module (E : Node_Id);
      procedure Visit_Operation_Declaration
        (E       : Node_Id;
         Binding : Boolean := True);
      procedure Visit_Specification (E : Node_Id);
      procedure Visit_Structure_Type (E : Node_Id);
      procedure Visit_Type_Declaration (E : Node_Id);
      procedure Visit_Union_Type (E : Node_Id);


      -----------
      -- Visit --
      -----------

      procedure Visit (E : Node_Id) is
      begin
         case FEN.Kind (E) is
            when K_Specification =>
               Visit_Specification (E);

            when K_Constant_Declaration =>
               Visit_Constant_Declaration (E);

            when K_Enumeration_Type =>
               Visit_Enumeration_Type (E);

            when K_Exception_Declaration =>
               Visit_Exception_Declaration (E);

            when K_Forward_Interface_Declaration =>
               Visit_Forward_Interface_Declaration (E);

            when K_Interface_Declaration =>
               Visit_Interface_Declaration (E);

            when K_Operation_Declaration =>
               Visit_Operation_Declaration (E);

            when K_Structure_Type =>
               Visit_Structure_Type (E);

            when K_Union_Type =>
               Visit_Union_Type (E);

            when K_Attribute_Declaration =>
               Visit_Attribute_Declaration (E);

            when K_Type_Declaration =>
               Visit_Type_Declaration (E);

            when K_Module =>
               Visit_Module (E);

            when others =>
               null;
         end case;
      end Visit;

      ---------------------------------
      -- Visit_Attribute_Declaration --
      ---------------------------------

      procedure Visit_Attribute_Declaration
        (E       : Node_Id;
         Binding : Boolean := True)
      is
         N : Node_Id;
         A : Node_Id;

      begin
         A := First_Entity (Declarators (E));
         while Present (A) loop
            Set_Main_Spec;

            --  Insert repository declaration
            --  We don't add the Repository_Id declaration in the case of an
            --  attribute inherited from the second until the last parent.

            if Scope_Entity (Identifier (A)) =
              Corresponding_Entity
              (FE_Node (Current_Entity))
            then
               Append_Node_To_List
                 (Map_Repository_Declaration (A),
                  Visible_Part (Current_Package));
            end if;

            --  Insert getter specification

            N := Map_Accessor_Declaration
              (Accessor => Getter, Attribute => A);
            Append_Node_To_List (N, Visible_Part (Current_Package));
            if Binding then
               Bind_FE_To_Stub (Identifier (A), N);
            end if;

            if not Is_Readonly (E) then
               Set_Main_Spec;

               --  Insert setter specification

               N := Map_Accessor_Declaration
                 (Accessor => Setter, Attribute => A);
               Append_Node_To_List (N, Visible_Part (Current_Package));
            end if;

            A := Next_Entity (A);
         end loop;
      end Visit_Attribute_Declaration;

      --------------------------------
      -- Visit_Constant_Declaration --
      --------------------------------

      procedure Visit_Constant_Declaration (E : Node_Id) is
         N          : Node_Id;
         Expression : Node_Id;
      begin
         Set_Main_Spec;

         Expression := Make_Literal (FEN.Value (E));

         --  Add a use clause for the type
         if Is_Base_Type (Type_Spec (E)) then
            N := Make_Used_Type (RE (Convert (FEN.Kind (Type_Spec (E)))));
            Append_Node_To_List (N, Visible_Part (Current_Package));
         end if;

         --  Some CORBA types need to be converted
         --  XXXX : Need more effort to handle types such as CORBA::String
         --         given as scoped names.

         case FEN.Kind (Type_Spec (E)) is
            when K_String =>
               Expression := Make_Subprogram_Call
                 (RE (RE_To_CORBA_String),
                  Make_List_Id (Expression));
            when K_Wide_String =>
               Expression := Make_Subprogram_Call
                 (RE (RE_To_CORBA_Wide_String),
                  Make_List_Id (Expression));
            when others =>
               null;
         end case;
         N := Make_Object_Declaration
           (Defining_Identifier => Map_Defining_Identifier (E),
            Constant_Present    => True,
            Object_Definition   => Map_Designator (Type_Spec (E)),
            Expression          => Expression);
         Bind_FE_To_Stub (Identifier (E), N);
         Append_Node_To_List (N, Visible_Part (Current_Package));
      end Visit_Constant_Declaration;

      ----------------------------
      -- Visit_Enumeration_Type --
      ----------------------------

      procedure Visit_Enumeration_Type (E : Node_Id) is
         Enumerator     : Node_Id;
         Enum_Literals  : List_Id;
         Enum_Literal   : Node_Id;
         Enum_Type_Decl : Node_Id;

      begin
         Set_Main_Spec;
         Enum_Literals := New_List (K_Enumeration_Literals);
         Enumerator := First_Entity (Enumerators (E));
         while Present (Enumerator) loop
            Enum_Literal := Map_Defining_Identifier (Enumerator);
            Append_Node_To_List (Enum_Literal, Enum_Literals);
            Enumerator := Next_Entity (Enumerator);
         end loop;

         Enum_Type_Decl :=
           Make_Full_Type_Declaration
           (Map_Defining_Identifier (E),
            Make_Enumeration_Type_Definition (Enum_Literals));

         Bind_FE_To_Stub  (Identifier (E), Enum_Type_Decl);
         Bind_FE_To_Type_Def (Identifier (E), Enum_Type_Decl);
         Append_Node_To_List
           (Enum_Type_Decl,
            Visible_Part (Current_Package));
         Append_Node_To_List
           (Map_Repository_Declaration (E),
            Visible_Part (Current_Package));
      end Visit_Enumeration_Type;

      ---------------------------------
      -- Visit_Exception_Declaration --
      ---------------------------------

      procedure Visit_Exception_Declaration (E : Node_Id) is
         Identifier : Node_Id;
         N          : Node_Id;

      begin
         Set_Main_Spec;

         --  Declaration of the exception

         Get_Name_String (To_Ada_Name (IDL_Name (FEN.Identifier (E))));
         Identifier := Make_Defining_Identifier (Name_Find);
         N := Make_Exception_Declaration (Identifier);
         Set_Correct_Parent_Unit_Name
           (Identifier,
            Defining_Identifier (Main_Package (Current_Entity)));
         Bind_FE_To_Stub (FEN.Identifier (E), N);
         Append_Node_To_List
           (N,
            Visible_Part (Current_Package));

         --  Definition of the "Exception_Name"_Members type

         Get_Name_String (To_Ada_Name (IDL_Name (FEN.Identifier (E))));
         Add_Str_To_Name_Buffer ("_Members");
         Identifier := Make_Defining_Identifier (Name_Find);
         Set_Correct_Parent_Unit_Name
           (Identifier,
            Defining_Identifier (Main_Package (Current_Entity)));
         N := Make_Full_Type_Declaration
           (Defining_Identifier => Identifier,
            Type_Definition     => Make_Derived_Type_Definition
            (RE (RE_IDL_Exception_Members),
             Make_Record_Definition
             (Map_Members_Definition (Members (E)))));
         Bind_FE_To_Type_Def (FEN.Identifier (E), N);
         Append_Node_To_List (N, Visible_Part (Current_Package));

         --  Insert repository declaration

         Append_Node_To_List
           (Map_Repository_Declaration (E),
            Visible_Part (Current_Package));

         --  Insert the Get_Members procedure specification
         N := Map_Get_Members_Spec (Identifier);
         Set_Correct_Parent_Unit_Name
           (Defining_Identifier (N),
            Defining_Identifier (Main_Package (Current_Entity)));

         Append_Node_To_List
           (N, Visible_Part (Current_Package));
      end Visit_Exception_Declaration;

      -----------------------------------------
      -- Visit_Forward_Interface_Declaration --
      -----------------------------------------

      procedure Visit_Forward_Interface_Declaration (E : Node_Id) is
         Identifier    : Node_Id;
         N             : Node_Id;
         Ref_Type_Node : Node_Id;
      begin
         --  The "Interface_Name"_Forward package is instanciated :
         --   * In the module main package if the interface is declared in a
         --     module.
         --   * In the XXXX_IDL_FILE main package if the interface is declared
         --     outside any module.
         Set_Main_Spec;

         --  Setting the interface as faorwarded to be able to add the
         --  additional code related to forwarding
         Set_Forwarded (Forward (E));

         Get_Name_String (To_Ada_Name (IDL_Name (FEN.Identifier (E))));
         Add_Str_To_Name_Buffer ("_Forward");
         Identifier := Make_Defining_Identifier (Name_Find);
         Set_Correct_Parent_Unit_Name
           (Identifier, Defining_Identifier (Main_Package (Current_Entity)));

         --  Package instanciation
         N := Make_Package_Instantiation
           (Defining_Identifier => Identifier,
            Generic_Package    => RU (RU_CORBA_Forward));
         Bind_FE_To_Instanciations
           (F                 => FEN.Identifier (E),
            Stub_Package_Node => N);
         --  Adding the binding between the interface declaration and the
         --  instanciated package.
         Bind_FE_To_Forward  (FEN.Identifier (Forward (E)), N);

         Append_Node_To_List (N, Visible_Part (Current_Package));

         --  This workaround is used to permit the use of the Ref type declared
         --  in the instanciated package.

         Identifier := Map_Ref_Type (E);
         Set_Correct_Parent_Unit_Name
           (Identifier, Defining_Identifier (N));
         Ref_Type_Node := Make_Full_Type_Declaration
           (Identifier,
            Make_Derived_Type_Definition
            (Subtype_Indication    =>
               Map_Ref_Type_Ancestor (E),
             Record_Extension_Part =>
               Make_Record_Type_Definition
             (Record_Definition => Make_Record_Definition (No_List))));
         --  We don't add this node!
         Bind_FE_To_Type_Def (FEN.Identifier (E), Ref_Type_Node);

      end Visit_Forward_Interface_Declaration;

      ---------------------------------
      -- Visit_Interface_Declaration --
      ---------------------------------

      procedure Visit_Interface_Declaration (E : Node_Id) is
         P        : Node_Id;
         N        : Node_Id;
         L        : List_Id;
         I        : Node_Id;
         Is_Local : constant Boolean := Is_Local_Interface (E);
      begin
         P := Map_IDL_Unit (E);
         Append_Node_To_List (P, Packages (Current_Entity));
         Push_Entity (P);
         Set_Main_Spec;
         L := Interface_Spec (E);

         --  Checking wether the interface inherits from another interface or
         --  not.
         --  Extract from the Ada mapping specifications :
         --
         --  "Single inheritance of IDL interface is direcly mapped to
         --   inheritance in the Ada mapping; that is, an interface with a
         --   parent is mapped to a tagged type that is derived from the tagged
         --   type mapped from the parent. The definitions of types, constants,
         --   and exceptions in the parent package are renamed or subtyped so
         --   that they are also inherited in accordance with the IDL
         --   semantics"
         --
         --  "The client side of multiple inheritence in IDL maps to single Ref
         --   tagged type, as with single inheritence, where the parent type is
         --   the first interface listed in the IDL parent interface list. The
         --   IDL compiler must generate additional primitive subprograms that
         --   correspond to the operations inherited from the second and
         --   subsequent parent interfaces listed in the IDL."

         if FEU.Is_Empty (L) then

            --  The reference type ancestor depends on the nature of the
            --  interface (unconstrained, local or abstract)

            N := Map_Ref_Type_Ancestor (E);
         else
            N := Expand_Designator
              (Type_Def_Node
               (BE_Node
                (Identifier
                 (Reference
                  (First_Entity
                   (L))))));
         end if;

         --  The designator of the reference type is also dependant of the
         --  nature of the interface

         I := Map_Ref_Type (E);

         N := Make_Full_Type_Declaration
           (I, Make_Derived_Type_Definition
            (Subtype_Indication    => N,
             Record_Extension_Part =>
               Make_Record_Type_Definition
             (Record_Definition => Make_Record_Definition (No_List))));
         Append_Node_To_List
           (N, Visible_Part (Current_Package));

         --  An Interface Declaration is also a type definition

         Bind_FE_To_Type_Def (Identifier (E), N);

         N := Map_Repository_Declaration (E);
         Append_Node_To_List
           (N, Visible_Part (Current_Package));
         Set_FE_Node (N, Identifier (E));

         N := First_Entity (Interface_Body (E));
         while Present (N) loop
            Visit (N);
            N := Next_Entity (N);
         end loop;

         --  In case of multiple inheritence, generate the mappings for
         --  the operations and attributes of the parents except the first one.
         Map_Inherited_Entities_Specs
           (Current_interface    => E,
            Visit_Operation_Subp => Visit_Operation_Declaration'Access,
            Visit_Attribute_Subp => Visit_Attribute_Declaration'Access,
            Stub                 => True);

         --  Local interfaces don't have Is_A function
         if not Is_Local then
            N := Visible_Is_A_Spec (E);
            Append_Node_To_List (N, Visible_Part (Current_Package));
         end if;

         --  If we handle a forwarded interfce we must instanciate the
         --  "Interface_Name"_Forward.Convert package
         if Is_Forwarded (E) then
            declare
               Pack_Inst : Node_Id;
               Gen_Pack  : Node_Id;
            begin
               Pack_Inst := RE (RE_Convert_Forward);
               Set_Correct_Parent_Unit_Name
                 (Pack_Inst,
                  Defining_Identifier (Main_Package (Current_Entity)));
               Gen_Pack := RE (RE_Convert);
               Set_Correct_Parent_Unit_Name
                 (Gen_Pack,
                  Defining_Identifier
                  (Forward_Node
                   (BE_Node
                    (Identifier
                     (E)))));

               --  To guarantee that the "with" clause of the generic package
               --  would be added, we use the Copy_Designator function.

               N := Make_Package_Instantiation
                 (Defining_Identifier => Defining_Identifier
                  (Pack_Inst),
                  Generic_Package     => Copy_Designator
                  (Gen_Pack),
                  Parameter_List      => Make_List_Id
                  (Map_Ref_Type (E)));
               Append_Node_To_List (N, Visible_Part (Current_Package));
            end;
         end if;

         if not Is_Local then
            N := Local_Is_A_Spec;
            Append_Node_To_List (N, Private_Part (Current_Package));
         end if;

         Pop_Entity;
      end Visit_Interface_Declaration;

      ------------------
      -- Visit_Module --
      ------------------

      procedure Visit_Module (E : Node_Id) is
         D : Node_Id;
         S : Node_Id;

      begin
         if not Map_Particular_CORBA_Parts (E, PK_Stub_Spec) then
            S := Map_IDL_Unit (E);
            Append_Node_To_List (S, Packages (Current_Entity));
            Push_Entity (S);
            Set_Main_Spec;
            Append_Node_To_List
              (Map_Repository_Declaration (E), Visible_Part (Current_Package));
            D := First_Entity (Definitions (E));
            while Present (D) loop
               Visit (D);
               D := Next_Entity (D);
            end loop;
            Pop_Entity;
         end if;
      end Visit_Module;

      ---------------------------------
      -- Visit_Operation_Declaration --
      ---------------------------------

      procedure Visit_Operation_Declaration
        (E       : Node_Id;
         Binding : Boolean := True)
      is

         Subp_Spec       : Node_Id;
         Profile         : List_Id;
         IDL_Param       : Node_Id;
         Ada_Param       : Node_Id;
         Mode            : Mode_Id := Mode_In;
         Returns         : Node_Id := No_Node;
         Type_Designator : Node_Id;
         Container       : constant Node_Id := Scope_Entity (Identifier (E));


         function Map_Correct_Designator (Entity : Node_Id) return Node_Id;

         ----------------------------
         -- Map_Correct_Designator --
         ----------------------------

         function Map_Correct_Designator (Entity : Node_Id) return Node_Id is
            Result    : Node_Id;
            Reference : Node_Id;
         begin
            Result := Map_Designator (Entity);

            --  Extract from the Ada mapping specification V. 1.2 concerning
            --  the mapping of operations :
            --  "The argument or return type shall be mapped from the IDL
            --  type except in the case of an argument or return type that is
            --  of the enclosing IDL unit type. Arguments or result types of
            --  the enclosing unit types shall be mapped to the class of the
            --  mapped reference type (for exemple, to Ref'Class for
            --  un constrained references)."

            if FEN.Kind (Entity) = K_Scoped_Name then
               Reference := FEN.Reference (Entity);
               --  Add here the different IDL unit possibilities :
               if FEN.Kind (Reference) = K_Interface_Declaration
                 and then Reference = Corresponding_Entity
                 (FE_Node (Current_Entity))
               then
                  Result := Make_Attribute_Designator
                    (Result, A_Class);
                  null;
               end if;
            end if;
            return Result;
         end Map_Correct_Designator;

      begin
         Profile := New_List (K_Parameter_Profile);

         --  Create a dispatching parameter

         Ada_Param := Make_Parameter_Specification
           (Make_Defining_Identifier (PN (P_Self)),
            Map_Ref_Type (Container));
         Append_Node_To_List (Ada_Param, Profile);

         --  Create an Ada subprogram parameter for each IDL subprogram
         --  parameter. Check whether there is one inout or out parameter.

         IDL_Param := First_Entity (Parameters (E));
         while Present (IDL_Param) loop
            Type_Designator := Map_Correct_Designator
              (Type_Spec (IDL_Param));

            Set_FE_Node (Type_Designator, Type_Spec (IDL_Param));
            Ada_Param := Make_Parameter_Specification
              (Map_Defining_Identifier (Declarator (IDL_Param)),
               Type_Designator,
               FEN.Parameter_Mode (IDL_Param));
            if FEN.Parameter_Mode (IDL_Param) /= Mode_In then
               Mode := Mode_Out;
            end if;
            Append_Node_To_List (Ada_Param, Profile);
            IDL_Param := Next_Entity (IDL_Param);
         end loop;

         --  If the IDL subprogram is a function, then check whether it
         --  has inout and out parameters. In this case, map the IDL
         --  function as an Ada procedure and not an Ada function.

         if FEN.Kind (Type_Spec (E)) /= K_Void then
            if Mode = Mode_In then
               Returns := Map_Correct_Designator (Type_Spec (E));
               Set_FE_Node (Returns, Type_Spec (E));

               --  If the IDL function is mapped as an Ada procedure, add a
               --  new parameter Returns to pass the returned value.

            else
               Type_Designator := Map_Correct_Designator
                 (Type_Spec (E));
               Set_FE_Node (Type_Designator, Type_Spec (E));
               Ada_Param := Make_Parameter_Specification
                 (Make_Defining_Identifier (PN (P_Returns)),
                  Type_Designator,
                  Mode_Out);
               Append_Node_To_List (Ada_Param, Profile);
            end if;
         end if;

         --  Add subprogram to main specification

         Set_Main_Spec;
         Subp_Spec := Make_Subprogram_Specification
           (Map_Defining_Identifier (E), Profile, Returns);
         Append_Node_To_List (Subp_Spec, Visible_Part (Current_Package));

         --  We don't add the Repository_Id declaration in the case of an
         --  Operation inherited from the second until the last parent.
         if Scope_Entity (Identifier (E)) =
           Corresponding_Entity
           (FE_Node (Current_Entity))
         then
            Append_Node_To_List
              (Map_Repository_Declaration (E),
               Visible_Part (Current_Package));
         end if;

         if Binding then
            Bind_FE_To_Stub (Identifier (E), Subp_Spec);
         end if;
      end Visit_Operation_Declaration;

      -------------------------
      -- Visit_Specification --
      -------------------------

      procedure Visit_Specification (E : Node_Id) is
         Definition : Node_Id;

      begin
         Push_Entity (Stub_Node (BE_Node (Identifier (E))));
         Definition := First_Entity (Definitions (E));
         while Present (Definition) loop
            Visit (Definition);
            Definition := Next_Entity (Definition);
         end loop;
         Pop_Entity;
      end Visit_Specification;

      --------------------------
      -- Visit_Structure_Type --
      --------------------------

      procedure Visit_Structure_Type (E : Node_Id) is
         N : Node_Id;

      begin
         Set_Main_Spec;
         N := Make_Full_Type_Declaration
           (Map_Defining_Identifier (E),
            Make_Record_Type_Definition
            (Make_Record_Definition
             (Map_Members_Definition (Members (E)))));
         Bind_FE_To_Stub (Identifier (E), N);
         Bind_FE_To_Type_Def (Identifier (E), N);
         Append_Node_To_List
           (N, Visible_Part (Current_Package));
         Append_Node_To_List
           (Map_Repository_Declaration (E), Visible_Part (Current_Package));
      end Visit_Structure_Type;

      ----------------------------
      -- Visit_Type_Declaration --
      ----------------------------

      procedure Visit_Type_Declaration (E : Node_Id) is
         D                : Node_Id;
         T                : Node_Id;
         N                : Node_Id;
         Is_Subtype       : Boolean := False;
         Type_Spec_Node   : Node_Id;
         Seq_Package_Inst : Node_Id;
         Fixed_Type_Node  : Node_Id;
      begin
         Set_Main_Spec;
         Type_Spec_Node := Type_Spec (E);

         --  The case of fixed point numbers is a special case :
         --  * The fixed type shall be mapped to an equivament Ada decimal type
         --  * For each declarator, a type definition shall be generated.
         if FEN.Kind (Type_Spec_Node) = K_Fixed_Point_Type then
            declare
               Fixed_Name : Name_Id;
            begin
               --  Defining a new Ada decimal type.
               Set_Str_To_Name_Buffer ("Fixed_");
               Add_Nat_To_Name_Buffer (Nat (N_Total (Type_Spec_Node)));
               Add_Char_To_Name_Buffer ('_');
               Add_Nat_To_Name_Buffer (Nat (N_Scale (Type_Spec_Node)));
               Fixed_Name := Name_Find;

               T := Make_Defining_Identifier (Fixed_Name);
               Set_Correct_Parent_Unit_Name
                 (T, Defining_Identifier (Main_Package (Current_Entity)));

               Fixed_Type_Node := Make_Full_Type_Declaration
                 (Defining_Identifier => T,
                  Type_Definition     => Make_Decimal_Type_Definition
                  (Type_Spec_Node));
               Append_Node_To_List
                 (Fixed_Type_Node,
                  Visible_Part (Current_Package));

            end;
         elsif FEN.Kind (Type_Spec_Node) = K_Sequence_Type then
            declare
               Bounded          : constant Boolean :=
                 Present (Max_Size (Type_Spec_Node));
               CORBA_Seq        : Node_Id;
               Seq_Package_Name : Name_Id;
               Prefix_Name      : Name_Id;
               Seq_Package_Node : Node_Id;
               Type_Node        : Node_Id;
               Max_S            : Value_Type;
            begin
               --  We create an instanciation of the generic package
               --  CORBA.Sequences.Bounded or CORBA.Sequences.Unbounded.
               --  Then, the sequence type is derived from the "Sequence"
               --  Type of the instanciated package.

               --  Creating the package name conforming to the Ada mapping
               --  specification.
               Set_Str_To_Name_Buffer ("IDL_SEQUENCE_");
               Prefix_Name := Name_Find;
               if Bounded then
                  CORBA_Seq := RU (RU_CORBA_Sequences_Bounded);
                  Max_S := Values.Value
                    (FEN.Value
                     (Max_Size
                      (Type_Spec_Node)));
                  Set_Dnat_To_Name_Buffer (Dnat (Max_S.IVal));
                  Prefix_Name := Add_Suffix_To_Name
                    (Name_Buffer (1 .. Name_Len) & "_",
                     Prefix_Name);

               else
                  CORBA_Seq := RU (RU_CORBA_Sequences_Unbounded);
               end if;

               if Is_Base_Type (Type_Spec (Type_Spec_Node)) then
                  Seq_Package_Name :=
                    (FEN.Image
                     (Base_Type
                      (Type_Spec
                       (Type_Spec_Node))));
               elsif FEN.Kind (Type_Spec (Type_Spec_Node)) = K_Scoped_Name
                 and then (FEN.Kind
                           (Reference (Type_Spec (Type_Spec_Node))) =
                           K_Interface_Declaration
                           or else
                           FEN.Kind
                           (Reference (Type_Spec (Type_Spec_Node))) =
                           K_Forward_Interface_Declaration
                           or else
                           FEN.Kind
                           (Reference (Type_Spec (Type_Spec_Node))) =
                           K_Simple_Declarator
                           or else
                           FEN.Kind
                           (Reference (Type_Spec (Type_Spec_Node))) =
                           K_Complex_Declarator
                           or else
                           FEN.Kind
                           (Reference (Type_Spec (Type_Spec_Node))) =
                           K_Structure_Type
                           or else
                           FEN.Kind
                           (Reference (Type_Spec (Type_Spec_Node))) =
                           K_Union_Type)
               then
                  Seq_Package_Name := FEU.Fully_Qualified_Name
                    (FEN.Identifier
                     (FEN.Reference
                      (Type_Spec
                       (Type_Spec_Node))),
                     Separator => "_");
               else
                  raise Program_Error;
               end if;
               Get_Name_String (Prefix_Name);
               Seq_Package_Name := Add_Prefix_To_Name
                 (Name_Buffer (1 .. Name_Len),
                  Seq_Package_Name);

               Type_Node := Map_Designator (Type_Spec (Type_Spec_Node));

               Seq_Package_Node := Make_Defining_Identifier
                 (Seq_Package_Name);
               Set_Correct_Parent_Unit_Name
                 (Seq_Package_Node,
                  Defining_Identifier
                  (Main_Package (Current_Entity)));

               if Bounded then
                  Seq_Package_Inst := Make_Package_Instantiation
                    (Defining_Identifier => Seq_Package_Node,
                     Generic_Package     => CORBA_Seq,
                     Parameter_List      => Make_List_Id
                     (Type_Node,
                      Make_Literal (FEN.Value (Max_Size (Type_Spec_Node)))));
               else
                  Seq_Package_Inst := Make_Package_Instantiation
                    (Defining_Identifier => Seq_Package_Node,
                     Generic_Package     => CORBA_Seq,
                     Parameter_List      => Make_List_Id (Type_Node));
               end if;
               Append_Node_To_List
                 (Seq_Package_Inst,
                  Visible_Part (Current_Package));

               T := Make_Defining_Identifier (TN (T_Sequence));
               Set_Correct_Parent_Unit_Name (T, Seq_Package_Node);
            end;
         else
            T := Map_Designator (Type_Spec_Node);
         end if;

         --  According to the Ada mapping specification. Most of the type
         --  definitions in an IDL file should be mapped to :
         --  "type ... is new ...;"
         --  However, there are exception to this rule :
         --  "interface Base {...};
         --   typedef Base Root;"
         --  sould be mapped : "subtype Root is Base.Ref;"

         --  Determining wether we map the type definition to a "type ... is
         --  new ...;" or a "subtype ... is ...;" statement.

         Is_Subtype := Is_Object_Type (Type_Spec (E));

         D := First_Entity (Declarators (E));
         while Present (D) loop
            if Kind (D) = K_Complex_Declarator then
               N := Make_Full_Type_Declaration
                 (Defining_Identifier => Map_Defining_Identifier (D),
                  Type_Definition     => Make_Array_Type_Definition
                  (Map_Range_Constraints
                   (FEN.Array_Sizes (D))
                   , T));
            else
               N := Make_Full_Type_Declaration
                 (Defining_Identifier => Map_Defining_Identifier (D),
                  Type_Definition     => Make_Derived_Type_Definition
                  (Subtype_Indication    => T,
                   Record_Extension_Part => No_Node,
                   Is_Subtype => Is_Subtype),
                  Is_Subtype => Is_Subtype);
            end if;
            Bind_FE_To_Stub (Identifier (D), N);
            Bind_FE_To_Type_Def (Identifier (D), N);
            if FEN.Kind (Type_Spec_Node) = K_Fixed_Point_Type then
               Bind_FE_To_Instanciations
                 (F              => Identifier (D),
                  Stub_Type_Node => Fixed_Type_Node);
            elsif FEN.Kind (Type_Spec_Node) = K_Sequence_Type then
               Bind_FE_To_Instanciations
                 (F                 => Identifier (D),
                  Stub_Package_Node => Seq_Package_Inst);
            end if;
            Append_Node_To_List
              (N, Visible_Part (Current_Package));
            Append_Node_To_List
              (Map_Repository_Declaration (D), Visible_Part (Current_Package));
            D := Next_Entity (D);
         end loop;
      end Visit_Type_Declaration;

      ----------------------
      -- Visit_Union_Type --
      ----------------------

      procedure Visit_Union_Type (E : Node_Id) is
         N : Node_Id;
         S : constant Node_Id := Switch_Type_Spec (E);
         T : Node_Id;
         L : List_Id;
         Literal_Parent : Node_Id := No_Node;


      begin
         Set_Main_Spec;
         T := Map_Designator (S);

         --  If the discriminator is an enumeration type, we must put the
         --  full names of literals
         if not Is_Base_Type (S) and then
           FEN.Kind (S) = K_Scoped_Name then
            Literal_Parent := Map_Designator
              (Scope_Entity
               (Identifier
                (Reference
                 (S))));
         end if;

         L := New_List (K_Component_List);
         Append_Node_To_List
           (Make_Variant_Part
            (Make_Defining_Identifier (CN (C_Switch)),
             Map_Variant_List
             (Switch_Type_Body (E),
              Literal_Parent)),
            L);
         N := Make_Full_Type_Declaration
           (Map_Defining_Identifier (E),
            Make_Record_Type_Definition
            (Make_Record_Definition (L)),
            Make_Component_Declaration
            (Make_Defining_Identifier (CN (C_Switch)), T,
             Make_Type_Attribute (T, A_First)));
         Bind_FE_To_Stub (Identifier (E), N);
         Bind_FE_To_Type_Def (Identifier (E), N);
         Append_Node_To_List
           (N, Visible_Part (Current_Package));
         Append_Node_To_List
           (Map_Repository_Declaration (E), Visible_Part (Current_Package));
      end Visit_Union_Type;
   end Package_Spec;

   package body Package_Body is

      procedure Visit_Attribute_Declaration (E : Node_Id);
      procedure Visit_Interface_Declaration (E : Node_Id);
      procedure Visit_Operation_Declaration (E : Node_Id);
      procedure Visit_Specification (E : Node_Id);
      procedure Visit_Exception_Declaration (E : Node_Id);
      procedure Visit_Module (E : Node_Id);

      -----------
      -- Visit --
      -----------

      procedure Visit (E : Node_Id) is
      begin
         case FEN.Kind (E) is
            when K_Specification =>
               Visit_Specification (E);

            when K_Constant_Declaration =>
               null;

            when K_Enumeration_Type =>
               null;

            when K_Exception_Declaration =>
               Visit_Exception_Declaration (E);

            when K_Interface_Declaration =>
               Visit_Interface_Declaration (E);

            when K_Operation_Declaration =>
               Visit_Operation_Declaration (E);

            when K_Structure_Type =>
               null;

            when K_Union_Type =>
               null;

            when K_Attribute_Declaration =>
               Visit_Attribute_Declaration (E);

            when K_Type_Declaration =>
               null;

            when K_Module =>
               Visit_Module (E);

            when others =>
               null;
         end case;
      end Visit;

      ---------------------------------
      -- Visit_Attribute_Declaration --
      ---------------------------------

      procedure Visit_Attribute_Declaration (E : Node_Id) is
         N : Node_Id;
         A : Node_Id;
         S : Node_Id;
         D : List_Id;
         B : List_Id;
      begin
         A := First_Entity (Declarators (E));
         while Present (A) loop
            Set_Main_Body;
            S := Stub_Node (BE_Node (Identifier (A)));
            D := Marshaller_Declarations (S);
            B := Marshaller_Body (S);
            N := Make_Subprogram_Implementation
              (Specification => S,
               Declarations => D,
               Statements => B);
            Append_Node_To_List (N, Statements (Current_Package));

            if not Is_Readonly (E) then
               Set_Main_Body;
               S := Next_Node (S);
               D := Marshaller_Declarations (S);
               B := Marshaller_Body (S);
               N := Make_Subprogram_Implementation
                 (Specification => S,
                  Declarations => D,
                  Statements => B);
               Append_Node_To_List (N, Statements (Current_Package));
            end if;

            A := Next_Entity (A);
         end loop;
      end Visit_Attribute_Declaration;

      ---------------------------------
      -- Visit_Exception_Declaration --
      ---------------------------------

      procedure Visit_Exception_Declaration (E : Node_Id) is
         Spec : Node_Id := No_Node;
         D    : constant List_Id := No_List;
         S    : constant List_Id := New_List (K_List_Id);
         N    : Node_Id;
         Parameters : List_Id;
      begin
         Set_Main_Body;

         Spec := Map_Get_Members_Spec
           (Expand_Designator
            (Type_Def_Node
             (BE_Node
              (FEN.Identifier
               (E)))));

         Parameters := New_List (K_List_Id);
         Append_Node_To_List
           (Make_Defining_Identifier (PN (P_From)), Parameters);
         Append_Node_To_List
           (Make_Defining_Identifier (PN (P_To)), Parameters);

         N := Make_Subprogram_Call
           (RE (RE_User_Get_Members),
            Parameters);
         Append_Node_To_List (N, S);

         N := Make_Subprogram_Implementation
           (Specification => Spec,
            Declarations => D,
            Statements => S);
         Append_Node_To_List (N, Statements (Current_Package));
      end Visit_Exception_Declaration;

      ------------------
      -- Visit_Module --
      ------------------

      procedure Visit_Module (E : Node_Id) is
         S : Node_Id;
         D : Node_Id;
      begin
         if not Map_Particular_CORBA_Parts (E, PK_Stub_Body) then
            S := Stub_Node (BE_Node (Identifier (E)));
            Push_Entity (S);
            D := First_Entity (Definitions (E));
            while Present (D) loop
               Visit (D);
               D := Next_Entity (D);
            end loop;
            Pop_Entity;
         end if;
      end Visit_Module;

      ---------------------
      -- Visit_Interface --
      ---------------------

      procedure Visit_Interface_Declaration (E : Node_Id) is
         N       : Node_Id;
         Is_Local : constant Boolean := Is_Local_Interface (E);
      begin
         N := BEN.Parent (Type_Def_Node (BE_Node (Identifier (E))));
         Push_Entity (BEN.IDL_Unit (Package_Declaration (N)));
         Set_Main_Body;
         N := First_Entity (Interface_Body (E));
         while Present (N) loop
            Visit (N);
            N := Next_Entity (N);
         end loop;

         --  In case of multiple inheritence, generate the mappings for
         --  the operations and attributes of the parents except the first one.
         Map_Inherited_Entities_Bodies
           (Current_interface    => E,
            Visit_Operation_Subp => Visit_Operation_Declaration'Access,
            Visit_Attribute_Subp => Visit_Attribute_Declaration'Access,
            Stub                 => True);

         if not Is_Local then
            N := Visible_Is_A_Body (E);
            Append_Node_To_List (N, Statements (Current_Package));
            N := Local_Is_A_Body (E);
            Append_Node_To_List (N, Statements (Current_Package));
         end if;

         Pop_Entity;
      end Visit_Interface_Declaration;


      ---------------------------------
      -- Visit_Operation_Declaration --
      ---------------------------------

      procedure Visit_Operation_Declaration (E : Node_Id) is
         S : Node_Id;
         D : List_Id;
         B : List_Id;
         N : Node_Id;
      begin
         Set_Main_Body;
         S := Stub_Node (BE_Node (Identifier (E)));
         D := Marshaller_Declarations (S);
         B := Marshaller_Body (S);
         N := Make_Subprogram_Implementation
           (Specification => S,
            Declarations => D,
            Statements => B);
         Append_Node_To_List (N, Statements (Current_Package));
      end Visit_Operation_Declaration;

      -------------------------
      -- Visit_Specification --
      -------------------------

      procedure Visit_Specification (E : Node_Id) is
         Definition : Node_Id;

      begin
         Push_Entity (Stub_Node (BE_Node (Identifier (E))));
         Definition := First_Entity (Definitions (E));
         while Present (Definition) loop
            Visit (Definition);
            Definition := Next_Entity (Definition);
         end loop;
         Pop_Entity;
      end Visit_Specification;

   end Package_Body;


   ---------------------
   -- Marshaller_Body --
   ---------------------

   function Marshaller_Body
     (Subp_Spec       : Node_Id)
     return            List_Id
   is
      Marshaller_Statements     : List_Id;
      N                         : Node_Id;
      C                         : Node_Id;
      P                         : List_Id;
      S                         : List_Id;
      Count                     : Natural;
      Return_T                  : Node_Id;
      I                         : Node_Id;
      Param                     : Node_Id;
      R                         : Name_Id;
      Operation_Name            : constant Name_Id
        := BEN.Name (Defining_Identifier (Subp_Spec));
      Declaration               : Node_Id;
      Container                 : constant Node_Id
        := Scope_Entity (FE_Node (Subp_Spec));
      Local_Interface           : constant Boolean :=
        (FEN.Kind (Container) = K_Interface_Declaration and then
         Is_Local_Interface (Container));

   begin
      Return_T := Return_Type (Subp_Spec);
      Marshaller_Statements := New_List (BEN.K_List_Id);

      --  Test if the Self_Ref_U is nil, if it's nil raise exception.

      --  In the case of an abstract interface, we should test wether the
      --  Object passed is a concrete interface type in which case we pass it
      --  as a reference, or wether it is a value type in wich case we pass
      --  it as a value. However, since valuetypes are not supported yet, we
      --  do only the first test.

      C := New_Node (BEN.K_Subprogram_Call);
      Set_Defining_Identifier
        (C, RE (RE_Raise_Inv_Objref));
      S := New_List (BEN.K_List_Id);
      Append_Node_To_List
        (RE (RE_Default_Sys_Member), S);
      Set_Actual_Parameter_Part (C, S);
      S := New_List (BEN.K_List_Id);
      Append_Node_To_List (C, S);
      C := New_Node (BEN.K_Subprogram_Call);
      Set_Defining_Identifier
        (C, RE (RE_Is_Nil));
      P := New_List (BEN.K_List_Id);
      Append_Node_To_List
        (Make_Defining_Identifier (VN (V_Self_Ref)), P);
      Set_Actual_Parameter_Part (C, P);
      N := Make_If_Statement
        (Condition => C,
         Then_Statements => S);
      Append_Node_To_List (N, Marshaller_Statements);

      if Local_Interface then
         declare
            Implem_Node  : Node_Id;
            Impl_Profile : constant List_Id := New_List (K_List_Id);
         begin
            N := Make_Subprogram_Call
              (Make_Defining_Identifier (SN (S_Entity_Of)),
               Make_List_Id
               (Make_Defining_Identifier (PN (P_Self))));

            --  Get the Object_Ptr type full name
            Implem_Node := Expand_Designator
              (Next_Node
               (Impl_Node
                (BE_Node
                 (Identifier
                  (Container)))));

            N := Make_Subprogram_Call
              (Implem_Node,
               Make_List_Id (N));

            Append_Node_To_List (N, Impl_Profile);

            --  Adding the rest of the parameters
            Count := Length (Parameter_Profile (Subp_Spec));
            if Count > 1 then
               P :=  BEN.Parameter_Profile (Subp_Spec);
               I := First_Node (P);
               I := Next_Node (I);
               loop
                  Append_Node_To_List
                    (Copy_Node (Defining_Identifier (I)),
                     Impl_Profile);
                  I := Next_Node (I);
                  exit when No (I);
               end loop;
            end if;

            N := Corresponding_Entity (FE_Node (Subp_Spec));
            Implem_Node := Impl_Node (BE_Node (FE_Node (Subp_Spec)));

            --  The case of an Set_XXX of an attribute

            if Kind (N) /= K_Operation_Declaration then
               Get_Name_String (BEN.Name (Defining_Identifier (Subp_Spec)));
               if Name_Buffer (1) = 'S' then
                  Implem_Node := Next_Node (Implem_Node);
               end if;
            end if;
            Implem_Node := Expand_Designator (Implem_Node);

            N := Make_Subprogram_Call
              (Implem_Node,
               Impl_Profile);

            if Present (Return_Type (Subp_Spec)) then
               N := Make_Return_Statement (N);
            end if;

            Append_Node_To_List (N, Marshaller_Statements);
         end;
      else

         --  Create argument list

         Set_Str_To_Name_Buffer
           ("Create the Argument list");
         Append_Node_To_List
           (Make_Ada_Comment (Name_Find),
            Marshaller_Statements);

         C := New_Node (K_Subprogram_Call);
         Set_Defining_Identifier
           (C, RE (RE_Create));
         P := New_List (BEN.K_List_Id);
         Append_Node_To_List
           (Make_Defining_Identifier (VN (V_Argument_List)), P);
         Set_Actual_Parameter_Part (C, P);
         Append_Node_To_List (C, Marshaller_Statements);
         Count := Length (Parameter_Profile (Subp_Spec));

         --  Add arguments  to argument  list

         if Count > 1 then
            P :=  BEN.Parameter_Profile (Subp_Spec);
            I := First_Node (P);
            I := Next_Node (I);
            loop
               P := Make_List_Id (Make_Designator (VN (V_Argument_List)));
               Get_Name_String (Operation_Name);
               Add_Str_To_Name_Buffer ("_Arg_Name_U_");
               Get_Name_String_And_Append (BEN.Name (Defining_Identifier (I)));
               N := Make_Designator (Name_Find);
               Append_Node_To_List (N, P);
               Set_Str_To_Name_Buffer ("Argument_U_");
               Get_Name_String_And_Append (BEN.Name (Defining_Identifier (I)));
               N := Make_Designator (Name_Find);
               N := Make_Subprogram_Call
                 (RE (RE_To_PolyORB_Any),
                  Make_List_Id (N));
               Append_Node_To_List (N, P);

               if BEN.Parameter_Mode (I) = Mode_Out then
                  N := RE (RE_ARG_OUT_1);
               elsif BEN.Parameter_Mode (I) = Mode_In then
                  N := RE (RE_ARG_IN_1);
               else
                  N := RE (RE_ARG_INOUT_1);
               end if;

               Append_Node_To_List (N, P);
               N := Make_Subprogram_Call
                 (RE (RE_Add_Item_1),
                  P);
               Append_Node_To_List (N, Marshaller_Statements);
               I := Next_Node (I);
               exit when No (I);
            end loop;
         end if;

         --  Create exception List
         --  We must verify that we handle an operation

         Declaration := FEN.Corresponding_Entity
           (BEN.FE_Node
            (Subp_Spec));

         if FEN.Kind (Declaration) = K_Operation_Declaration and then
           not FEU.Is_Empty (Exceptions (Declaration)) then
            declare
               Excep_FE : Node_Id;
               Excep_TC : Node_Id;
            begin
               Set_Str_To_Name_Buffer
                 ("Create the Exception list");
               Append_Node_To_List
                 (Make_Ada_Comment (Name_Find),
                  Marshaller_Statements);
               N := Make_Subprogram_Call
                 (RE (RE_Create_List_1),
                  Make_List_Id
                  (Make_Designator (VN (V_Exception_List))));
               Append_Node_To_List (N, Marshaller_Statements);
               Excep_FE := First_Entity (Exceptions (Declaration));
               while Present (Excep_FE) loop
                  --  Getting the TC_"Exception_Name" identifier. It is
                  --  declarated at the first place in the Helper spec.
                  Excep_TC := TC_Node
                    (BE_Node (Identifier (Reference (Excep_FE))));
                  Excep_TC := Expand_Designator (Excep_TC);
                  N := Make_Subprogram_Call
                    (RE (RE_Add_1),
                     Make_List_Id
                     (Make_Designator
                      (VN (V_Exception_List)),
                      Excep_TC));
                  Append_Node_To_List (N, Marshaller_Statements);

                  Excep_FE := Next_Entity (Excep_FE);
               end loop;
            end;

         end if;

         --  Set result type (maybe void)

         Get_Name_String (Operation_Name);
         Add_Char_To_Name_Buffer ('_');
         Get_Name_String_And_Append (VN (V_Result_Name));
         R := Name_Find;
         C := Make_Subprogram_Call
           (Defining_Identifier   => RE (RE_Identifier),
            Actual_Parameter_Part =>
              Make_List_Id (Make_Defining_Identifier (R)));

         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Name)),
            Expression    => C);
         P := Make_List_Id (N);

         if No (Return_T) then
            Param := RE (RE_TC_Void);
         else
            Param := Get_TC_Node (FE_Node (Return_T));
         end if;

         C := Make_Subprogram_Call
           (Defining_Identifier  => RE (RE_Get_Empty_Any),
            Actual_Parameter_Part => Make_List_Id (Param));
         C := Make_Subprogram_Call
           (RE (RE_To_PolyORB_Any), Make_List_Id (C));
         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Argument)),
            Expression    => C);
         Append_Node_To_List (N, P);

         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Arg_Modes)),
            Expression    => Make_Literal (New_Integer_Value (0, 0, 10)));
         Append_Node_To_List (N, P);

         N := Make_Record_Aggregate (P);
         N := Make_Return_Statement (N);
         Get_Name_String (Operation_Name);
         Add_Char_To_Name_Buffer ('_');
         Get_Name_String_And_Append (VN (V_Result));
         R := Name_Find;

         I := Make_Subprogram_Call
           (Make_Defining_Identifier (GN (Pragma_Inline)),
            Make_List_Id (Make_Designator (R)));
         C := Make_Subprogram_Specification
           (Make_Defining_Identifier (R),
            No_List,
            RE (RE_NamedValue));
         N := Make_Subprogram_Implementation
           (C,
            Make_List_Id (Make_Pragma_Statement (I)),
            Make_List_Id (N));
         Append_Node_To_List (N, Statements (Current_Package));

         --  Creating the request

         Set_Str_To_Name_Buffer
           ("Creating the request");
         Append_Node_To_List
           (Make_Ada_Comment (Name_Find),
            Marshaller_Statements);

         N := Make_Subprogram_Call
           (RE (RE_Ref_2),
            Make_List_Id (Make_Defining_Identifier (PN (P_Self))));
         N := Make_Subprogram_Call
           (RE (RE_To_PolyORB_Ref), Make_List_Id (N));
         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Target)),
            Expression    => N);
         P := Make_List_Id (N);

         Get_Name_String (Operation_Name);
         Add_Char_To_Name_Buffer ('_');
         Get_Name_String_And_Append (VN (V_Operation_Name));
         R := Name_Find;
         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Operation)),
            Expression    => Make_Defining_Identifier (R));
         Append_Node_To_List (N, P);
         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Arg_List)),
            Expression    => Make_Defining_Identifier (VN (V_Argument_List)));
         Append_Node_To_List (N, P);
         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Result)),
            Expression    => Make_Defining_Identifier (VN (V_Result)));
         Append_Node_To_List (N, P);

         --  If the operation thows an exception, we add an additional flag to
         --  the Create_Request function.

         if FEN.Kind (Declaration) = K_Operation_Declaration and then
           not FEU.Is_Empty (Exceptions (Declaration)) then
            N := Make_Subprogram_Call
              (RE (RE_To_PolyORB_Ref_1),
               Make_List_Id
               (Make_Designator
                (VN (V_Exception_List))));

            N := Make_Component_Association
              (Selector_Name => Make_Defining_Identifier (PN (P_Exc_List)),
               Expression    => N);
            Append_Node_To_List (N, P);
         end if;

         N := Make_Component_Association
           (Selector_Name => Make_Defining_Identifier (PN (P_Req)),
            Expression    => Make_Defining_Identifier (VN (V_Request)));
         Append_Node_To_List (N, P);

         --  Handling the case of Oneway Operations.
         --  Extract from The CORBA mapping specification : "IDL oneway
         --  operations are mapped the same as other operation; that is, there
         --  is no indication wether an operation is oneway or not in the
         --  mapped Ada specification".
         --
         --  The extract above means that the call to a onway operation is
         --  performed in the same way as a call to a classic synchronous
         --  operation. However, the ORB need to know oneway operations.
         --  The stub precise that by adding an additional parameter to the
         --  procedure "PolyORB.Requests.Create_Request". This additional
         --  parameter indicate the calling way of the operation (see the file
         --  polyorb-requests.ads for more information about differents ways of
         --  calls)
         --
         --  First of all, verify that we are handling an operation
         --  decalaration (and not an attribute declaration)

         Declaration := FEN.Corresponding_Entity
           (BEN.FE_Node
            (Subp_Spec));

         if FEN.Kind (Declaration) = K_Operation_Declaration and then
           FEN.Is_Oneway (Declaration) then
            N := Make_Component_Association
              (Selector_Name => Make_Defining_Identifier (PN (P_Req_Flags)),
               Expression    => RE (RE_Sync_With_Transport));
            Append_Node_To_List (N, P);
         end if;

         N := Make_Subprogram_Call
           (RE (RE_Create_Request),
            P);
         Append_Node_To_List (N, Marshaller_Statements);

         --  Invoking the request (synchronously or asynchronously), it
         --  depends on the type of the operation (oneway or not).

         Set_Str_To_Name_Buffer
           ("Invoking the request (synchronously or asynchronously)");
         Append_Node_To_List
           (Make_Ada_Comment (Name_Find),
            Marshaller_Statements);

         N := Make_Subprogram_Call
           (RE (RE_Flags),
            Make_List_Id (Make_Literal (Int0_Val)));
         N := Make_Subprogram_Call
           (RE (RE_Client_Invoke),
            Make_List_Id
            (Make_Defining_Identifier (VN (V_Request)),
             N));
         Append_Node_To_List (N, Marshaller_Statements);

         --  Raise eventual exceptions

         Set_Str_To_Name_Buffer
           ("Raise eventual exceptions");
         Append_Node_To_List
           (Make_Ada_Comment (Name_Find),
            Marshaller_Statements);

         P := New_List (K_List_Id);
         C := Make_Designator
           (Designator => PN (P_Argument),
            Parent     => VN (V_Result));
         N := Make_Assignment_Statement
           (C,
            Make_Designator
            (Designator => PN (P_Exception_Info),
             Parent     => VN (V_Request)));
         Append_Node_To_List (N, P);
         N := Make_Subprogram_Call
           (RE (RE_Destroy_Request),
            Make_List_Id
            (Make_Designator (VN (V_Request))));
         Append_Node_To_List (N, P);
         N := Make_Subprogram_Call
           (RE (RE_Raise_From_Any),
            Make_List_Id (Copy_Node (C)));
         Append_Node_To_List (N, P);
         N := Make_Subprogram_Call
           (RE (RE_Is_Empty),
            Make_List_Id (Make_Designator
                          (Designator => PN (P_Exception_Info),
                           Parent     => VN (V_Request))));
         N := Make_Expression (N, Op_Not);
         N := Make_If_Statement
           (N, P, No_List);
         Append_Node_To_List (N, Marshaller_Statements);
         N := Make_Subprogram_Call
           (RE (RE_Destroy_Request),
            Make_List_Id (Make_Designator (VN (V_Request))));
         Append_Node_To_List (N, Marshaller_Statements);

         --  Retrieve return value

         if Present (Return_T) then
            Set_Str_To_Name_Buffer
              ("Retrieve the return value");
            Append_Node_To_List
              (Make_Ada_Comment (Name_Find),
               Marshaller_Statements);

            N := Get_From_Any_Node (FE_Node (Return_T));

            C := Make_Subprogram_Call
              (RE (RE_To_CORBA_Any),
               Make_List_Id (Copy_Node (C)));
            N := Make_Return_Statement
              (Make_Subprogram_Call (N, Make_List_Id (C)));
            Append_Node_To_List (N, Marshaller_Statements);
         end if;

         --  Retrieve out arguments values

         if Count > 1 then
            P :=  BEN.Parameter_Profile (Subp_Spec);
            I := First_Node (P);
            I := Next_Node (I);
            loop
               if  BEN.Parameter_Mode (I) = Mode_Out
                 or else BEN.Parameter_Mode (I) = Mode_Inout then
                  declare
                     Param_Name      : Name_Id;
                     New_Name        : Name_Id;
                     From_Any_Helper : Node_Id;
                     Par_Type        : Node_Id;
                  begin
                     Set_Str_To_Name_Buffer
                       ("Retrieve out argument");
                     Append_Node_To_List
                       (Make_Ada_Comment (Name_Find),
                        Marshaller_Statements);

                     Param_Name := BEN.Name (Defining_Identifier (I));
                     New_Name := Add_Prefix_To_Name
                       ("Argument_U_", Param_Name);

                     Par_Type := BEN.FE_Node (Parameter_Type (I));
                     From_Any_Helper := Get_From_Any_Node (Par_Type);

                     N := Make_Subprogram_Call
                       (From_Any_Helper,
                        Make_List_Id (Make_Designator (New_Name)));

                     --  If the parameter type is a Class wide type, we hace to
                     --  cast the value of the parameter before assigning it
                     if BEN.Kind (Parameter_Type (I))
                       = K_Attribute_Designator
                     then
                        N := Make_Subprogram_Call
                          (Copy_Designator
                           (Parameter_Type (I)),
                           Make_List_Id (N));
                     end if;

                     N := Make_Assignment_Statement
                       (Make_Designator (Param_Name),
                        N);
                     Append_Node_To_List (N, Marshaller_Statements);
                  end;
               end if;
               I := Next_Node (I);
               exit when No (I);
            end loop;
         end if;
      end if;

      return Marshaller_Statements;
   end Marshaller_Body;

   -----------------------------
   -- Marshaller_Declarations --
   -----------------------------

   function Marshaller_Declarations (Subp_Spec : Node_Id) return List_Id is
      L                : List_Id;
      P                : List_Id;
      N                : Node_Id;
      V                : Value_Id;
      C                : Node_Id;
      I                : Node_Id;
      X                : Name_Id;
      D                : Node_Id;
      R                : Name_Id;
      Operation_Name   : constant Name_Id
        := BEN.Name (Defining_Identifier (Subp_Spec));
      FE               : constant Node_Id
        := Corresponding_Entity (FE_Node (Subp_Spec));
      TC_Node          : Node_Id;
      Declaration      : Node_Id;
      To_Any_Type_Name : Name_Id := No_Name;
      Param_Type_Name  : Name_Id := No_Name;
      Cast_Node        : Node_Id;
      Container        : constant Node_Id
        := Scope_Entity (FE_Node (Subp_Spec));
      Local_Interface  : constant Boolean :=
        (FEN.Kind (Container) = K_Interface_Declaration and then
         Is_Local_Interface (Container));
   begin
      L := New_List (BEN.K_List_Id);

      if not Local_Interface then

         --  Arg_List_U declaration

         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (VN (V_Argument_List)),
            Constant_Present    => False,
            Object_Definition   => RE (RE_Ref_3),
            Expression          => No_Node);
         Append_Node_To_List (N, L);

         P := Parameter_Profile (Subp_Spec);
         I := First_Node (P);
         I := Next_Node (I);
         while Present (I) loop

            --  Operation_Name_Arg_Name_U_X declaration
            --  Operation_Name_Arg_Name_U_X : PolyORB.Types.Identifier
            --    := PolyORB.Types.To_PolyORB_String ("X")
            --  ** where X is the parameter name.

            X := BEN.Name (Defining_Identifier (I));
            C := Make_Subprogram_Call
              (Defining_Identifier   => RE (RE_To_PolyORB_String),
               Actual_Parameter_Part =>
                 Make_List_Id (Make_Literal (New_String_Value (X, False))));

            Get_Name_String (Operation_Name);
            Add_Str_To_Name_Buffer ("_Arg_Name_U_");
            Get_Name_String_And_Append (X);
            R := Name_Find;
            N := Make_Object_Declaration
              (Defining_Identifier => Make_Defining_Identifier (R),
               Constant_Present => False,
               Object_Definition => RE (RE_Identifier),
               Expression => C);
            Append_Node_To_List (N, L);

            --  Argument_U_X declaration
            --  Argument_U_X : CORBA.Any := Y.Helper.To_Any (X);
            --  ** where X is the parameter name.
            --  ** where Y is the fully qualified current package Name.

            if BEN.Parameter_Mode (I) = Mode_Out then
               D := RE (RE_Get_Empty_Any);
               TC_Node := Get_TC_Node (BEN.FE_Node (Parameter_Type (I)));

               C :=  Make_Subprogram_Call
                 (Defining_Identifier   => D,
                  Actual_Parameter_Part =>
                    Make_List_Id (TC_Node));
            else
               D := Get_To_Any_Node (BEN.FE_Node (Parameter_Type (I)));

               --  Get the types of the argument of the To_Any function and
               --  of the actual parameter if they are available

               if not Is_Base_Type (BEN.FE_Node (Parameter_Type (I)))
                 and then Present
                 (BE_Node
                  (Identifier
                   (Reference
                    (Corresponding_Entity
                     (Identifier
                      (FE_Node
                       (Parameter_Type
                        (I))))))))
               then
                  To_Any_Type_Name := Fully_Qualified_Name
                    (Parameter_Type
                     (First_Node
                      (Parameter_Profile
                       (To_Any_Node
                        (BE_Node
                         (Identifier
                          (Reference
                           (Corresponding_Entity
                            (Identifier
                             (FE_Node
                              (Parameter_Type
                               (I))))))))))));
                  Param_Type_Name := Fully_Qualified_Name
                    (BEN.Parameter_Type (I));
               end if;

               --  Here, we are in the case where we call the To_Any method.
               --  If the parameter type is XXX.Ref'Class, we must cast the
               --  parameter before giving it to the function.
               --  We just test wether the two type names are equal.

               if Param_Type_Name /= To_Any_Type_Name then
                  Cast_Node := Make_Subprogram_Call
                    (Defining_Identifier =>
                       Make_Defining_Identifier (To_Any_Type_Name),
                     Actual_Parameter_Part =>
                       Make_List_Id (Make_Defining_Identifier (X)));
               else
                  Cast_Node := Make_Defining_Identifier (X);
               end if;

               C := Make_Subprogram_Call
                 (Defining_Identifier   => D,
                  Actual_Parameter_Part =>
                    Make_List_Id (Cast_Node));

            end if;

            Set_Str_To_Name_Buffer ("Argument_U_");
            Get_Name_String_And_Append (X);
            R := Name_Find;
            N := Make_Object_Declaration
              (Defining_Identifier => Make_Defining_Identifier (R),
               Constant_Present => False,
               Object_Definition => RE (RE_Any),
               Expression => C);
            Append_Node_To_List (N, L);
            I := Next_Node (I);
         end loop;

         --  Operation_Name_U declaration

         --  Add underscore to the operation name if the the subprogram is
         --  an accessor funtion

         if FEN.Kind (FE) = K_Simple_Declarator
           or else
           FEN.Kind (FE) = K_Complex_Declarator
         then
            V := New_String_Value
              (Add_Prefix_To_Name ("_", Operation_Name), False);
         else
            V := New_String_Value (Operation_Name, False);
         end if;

         Get_Name_String (Operation_Name);
         Add_Char_To_Name_Buffer ('_');
         Get_Name_String_And_Append (VN (V_Operation_Name));
         R := Name_Find;
         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (R),
            Constant_Present    => True,
            Object_Definition   => RE (RE_String_2),
            Expression          => Make_Literal (V));
         Append_Node_To_List (N, Statements (Current_Package));

         --  Request_U declaration

         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (VN (V_Request)),
            Constant_Present    => False,
            Object_Definition   => RE (RE_Request_Access),
            Expression          => No_Node);
         Append_Node_To_List (N, L);

         --  Exception_List_U declaration
         --  We must verify that we handle an operation

         Declaration := FEN.Corresponding_Entity
           (BEN.FE_Node
            (Subp_Spec));

         if FEN.Kind (Declaration) = K_Operation_Declaration and then
           not FEU.Is_Empty (Exceptions (Declaration)) then
            N := Make_Object_Declaration
              (Defining_Identifier =>
                 Make_Defining_Identifier (VN (V_Exception_List)),
               Constant_Present    => False,
               Object_Definition   => RE (RE_Ref_5),
               Expression          => No_Node);
            Append_Node_To_List (N, L);
         end if;

         --  Result_U declaration
         --  Result_U : PolyORB.Any.NamedValue := [Operation_Name]_Result_V;

         Get_Name_String (Operation_Name);
         Add_Char_To_Name_Buffer ('_');
         Get_Name_String_And_Append (VN (V_Result));
         R := Name_Find;
         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (VN (V_Result)),
            Constant_Present    => False,
            Object_Definition   => RE (RE_NamedValue),
            Expression          =>
              Make_Subprogram_Call
            (Make_Designator (R), No_List));
         Append_Node_To_List (N, L);

         --  Result_Name_U declaration :
         --  Result_Name_U : CORBA.String := CORBA.To_CORBA_String ("Result");

         V := New_String_Value (PN (P_Result), False);
         C := Make_Subprogram_Call
           (Defining_Identifier   => RE (RE_To_CORBA_String),
            Actual_Parameter_Part =>
              Make_List_Id (Make_Literal (V)));
         Get_Name_String (Operation_Name);
         Add_Char_To_Name_Buffer ('_');
         Get_Name_String_And_Append (VN (V_Result_Name));
         R := Name_Find;
         N := Make_Object_Declaration
           (Defining_Identifier =>
              Make_Defining_Identifier (R),
            Constant_Present    => False,
            Object_Definition   => RE (RE_String_0),
            Expression          => C);
         Append_Node_To_List (N, Statements (Current_Package));

      end if;

      --  Self_Ref_U declaration
      --  Self_Ref_U : CORBA.Object.Ref  := CORBA.Object.Ref (Self);

      C := Make_Subprogram_Call
        (Defining_Identifier   =>
           RE (RE_Ref_2),
         Actual_Parameter_Part =>
           Make_List_Id (Make_Defining_Identifier (PN (P_Self))));

      N := Make_Object_Declaration
        (Defining_Identifier =>
           Make_Defining_Identifier (VN (V_Self_Ref)),
         Constant_Present    => False,
         Object_Definition   => RE (RE_Ref_2),
         Expression          => C);
      Append_Node_To_List (N, L);
--        Map_Ref_Type_Ancestor (Container),

      return L;
   end Marshaller_Declarations;

   ---------------------
   -- Local_Is_A_Body --
   ---------------------

   function Local_Is_A_Body
     (E    : Node_Id;
      Spec : Node_Id := No_Node)
     return Node_Id is
      N                : Node_Id;
      S                : constant List_Id := New_List (K_List_Id);
      M                : Node_Id;
      Repository_Id    : Node_Id;
      Rep_Value        : Value_Id;
      Parent_Statement : Node_Id;

      --  This function returns a logical "or else" expression. The operands
      --  of the expression are calls to CORBA.Is_Equivalent function on
      --  all the parents (direct parents as well as in direct parents) of the
      --  interface. It returns a null node in the case where the interface
      --  does not herit from another interface.
      function Is_Equivalent_Statement (E : Node_Id) return Node_Id;

      -----------------------------
      -- Is_Equivalent_Statement --
      -----------------------------

      function Is_Equivalent_Statement (E : Node_Id) return Node_Id is
         Result           : Node_Id := No_Node;
         Parent_Statement : Node_Id;
         Par_Int          : Node_Id;
         L                : List_Id;
         Rep_Id           : Node_Id;
      begin
         pragma Assert (FEN.Kind (E) = K_Interface_Declaration);
         L := Interface_Spec (E);
         if not FEU.Is_Empty (L) then
            Par_Int := First_Entity (L);
            while Present (Par_Int) loop
               Rep_Id := Expand_Designator
                 (Next_Node
                  (Type_Def_Node
                   (BE_Node
                    (Identifier
                     (Reference
                      (Par_Int))))));
               if Present (Result) then
                  Result := Make_Expression
                    (Result,
                     Op_Or_Else,
                     Make_Subprogram_Call
                     (RE (RE_Is_Equivalent),
                      Make_List_Id
                      (Make_Defining_Identifier (PN (P_Logical_Type_Id)),
                       Rep_Id)));
               else
                  Result := Make_Subprogram_Call
                    (RE (RE_Is_Equivalent),
                     Make_List_Id
                     (Make_Defining_Identifier (PN (P_Logical_Type_Id)),
                      Rep_Id));
               end if;
               --  Adding recursivly the parents of parents.
               Parent_Statement := Is_Equivalent_Statement
                 (Reference
                  (Par_Int));
               if Present (Parent_Statement) then
                  Result := Make_Expression
                    (Result,
                     Op_Or_Else,
                     Parent_Statement);
               end if;
               Par_Int := Next_Entity (Par_Int);
            end loop;
         end if;
         return Result;
      end Is_Equivalent_Statement;

   begin
      --  getting the Repository_Id constant
      N := Type_Def_Node (BE_Node (Identifier (E)));
      N := Next_Node (N);
      Repository_Id := Expand_Designator (N);

      N := Make_Subprogram_Call
        (RE (RE_Is_Equivalent),
         Make_List_Id
         (Make_Defining_Identifier (PN (P_Logical_Type_Id)),
          Repository_Id));

      if FEN.Kind (E) = K_Interface_Declaration then
         Set_Str_To_Name_Buffer ("IDL:omg.org/CORBA/Object:1.0");
      else
         Set_Str_To_Name_Buffer ("IDL:omg.org/CORBA/ValueBase:1.0");
      end if;

      Rep_Value := New_String_Value (Name_Find, False);
      M := Make_Subprogram_Call
        (RE (RE_Is_Equivalent),
         Make_List_Id
         (Make_Defining_Identifier (PN (P_Logical_Type_Id)),
          Make_Literal (Rep_Value)));
      N := Make_Expression
        (N, Op_Or_Else, M);

      --  Adding the parents.
      Parent_Statement := Is_Equivalent_Statement (E);
      if Present (Parent_Statement) then
         N := Make_Expression
           (N, Op_Or_Else, Parent_Statement);
      end if;
      N := Make_Expression
        (N, Op_Or_Else, RE (RE_False));
      N := Make_Return_Statement (N);
      Append_Node_To_List (N, S);

      --  getting the spec of the Is_A function
      if Spec = No_Node then
         N := Local_Is_A_Spec;
      else
         N := Spec;
      end if;
      N := Make_Subprogram_Implementation
        (N, No_List, S);
      return N;
   end Local_Is_A_Body;

   ---------------------
   -- Local_Is_A_Spec --
   ---------------------

   function Local_Is_A_Spec return Node_Id is
      N       : Node_Id;
      Profile : List_Id;
      Param   : Node_Id;
   begin
      Param := Make_Parameter_Specification
        (Make_Defining_Identifier (PN (P_Logical_Type_Id)),
         RE (RE_String_2));
      Profile := New_List (K_Parameter_Profile);
      Append_Node_To_List (Param, Profile);
      N := Make_Subprogram_Specification
        (Make_Defining_Identifier (SN (S_Is_A)),
         Profile,
         RE (RE_Boolean));
      return N;
   end Local_Is_A_Spec;

   -----------------------
   -- Visible_Is_A_Body --
   -----------------------

   function Visible_Is_A_Body (E : Node_Id) return Node_Id is
      N : Node_Id;
      M : Node_Id;
      S : constant List_Id := New_List (K_List_Id);
   begin
      M := Make_Subprogram_Call
        (RE (RE_Ref_2),
         Make_List_Id (Make_Defining_Identifier (PN (P_Self))));
      M := Make_Subprogram_Call
        (RE (RE_Is_A),
         Make_List_Id (M, Make_Defining_Identifier (PN (P_Logical_Type_Id))));
      N := Make_Subprogram_Call
        (Make_Defining_Identifier (SN (S_Is_A)),
         Make_List_Id (Make_Designator (PN (P_Logical_Type_Id))));
      N := Make_Expression
        (RE (RE_False),
         Op_Or_Else,
         Make_Expression
         (N,
          Op_Or_Else,
          M));
      N := Make_Return_Statement (N);
      Append_Node_To_List (N, S);
      N := Make_Subprogram_Implementation
        (Visible_Is_A_Spec (E), No_List, S);
      return N;
   end Visible_Is_A_Body;

   -----------------------
   -- Visible_Is_A_Spec --
   -----------------------

   function Visible_Is_A_Spec (E : Node_Id) return Node_Id is
      N       : Node_Id;
      Profile : List_Id;
      Param   : Node_Id;
   begin
      Profile := New_List (K_Parameter_Profile);
      Param := Make_Parameter_Specification
        (Make_Defining_Identifier (PN (P_Self)),
         Map_Ref_Type (E));
      Append_Node_To_List (Param, Profile);
      Param := Make_Parameter_Specification
        (Make_Defining_Identifier (PN (P_Logical_Type_Id)),
         RE (RE_String_2));
      Append_Node_To_List (Param, Profile);
      N := Make_Subprogram_Specification
        (Make_Defining_Identifier (SN (S_Is_A)),
         Profile,
         RE (RE_Boolean));
      return N;
   end Visible_Is_A_Spec;
end Backend.BE_Ada.Stubs;
