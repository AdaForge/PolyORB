#include <adabe.h>

adabe_field::adabe_field(AST_Type *ft, UTL_ScopedName *n, UTL_StrList *p)
	: AST_Field(ft, n, p),
	  AST_Decl(AST_Decl::NT_field, n, p),
	  adabe_name(AST_Decl::NT_field, n, p)
{
}

void
adabe_field::produce_ads(dep_list& with, string &body, string &previous) 
{
  compute_ada_name();
  body += "      " + get_ada_local_name();
  body += " : ";
  AST_Decl *b = field_type();
#ifdef DEBUG_FIELD
  cerr << "before the dump name of the field " << endl;
#endif 
  body += dynamic_cast<adabe_name *>(b)->dump_name(with, previous); 
#ifdef DEBUG_FIELD
  cerr << "after the dump name of the field " << endl;
#endif 
  body += ";\n";
}

/*
  void
  adabe_field::produce_adb(dep_list& with,string &body, string &previous) 
  {
  produce_ads(with, &body, &previous);
  }
  
  ///////////////// perhaps useless /////////////////////
  void
  adabe_field::produce_impl_ads(dep_list& with,string &body, string &previous) 
  {
  produce_ads( with, &body, &previous);
  }
  
  void
  adabe_field::produce_impl_adb(dep_list& with,string &body, string &previous) 
  {
  produce_ads(with, &body, &previous);
  }
*/

void
adabe_field::produce_marshal_adb(dep_list& with, string &body, string &marshall, string &unmarshall, string &align_size)
{
  string previous = "";
  string name = (dynamic_cast<adabe_name *>(field_type()))->marshal_name(with, previous); 

  body += previous;
  
  marshall += "      Marshall(A.";
  marshall += get_ada_local_name ();
  marshall += ",S) ;\n";
  
  unmarshall += "      UnMarshall(A.";
  unmarshall += get_ada_local_name ();
  unmarshall += ",S) ;\n";
  
  align_size += "      Tmp := Align_Size(A.";
  align_size += get_ada_local_name ();
  align_size += ", Tmp) ;\n";

  set_already_defined();
}
  
IMPL_NARROW_METHODS1(adabe_field, AST_Field)
IMPL_NARROW_FROM_DECL(adabe_field)












