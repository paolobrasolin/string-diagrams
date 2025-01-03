# We need two makeindex runs with custom options to generate indices:
#   * idx->ind: `makeindex -s gind.ist -o %D %S`
#   * glo->gls: `makeindex -s gglo.ist -o %D %S`
# While the default makeindex commands affords us passing options (`$makeindex = "makeindex %O -o %D %S";`), latexmk has an hardcoded rule for idx->ind (that cannot be disabled) and always runs `run_makeindex` (which contains unhelpful logic).
# To run idx->ind we piggyback the hardcoded rule and override `run_makeindex`:
sub run_makeindex { return Run_subst( $makeindex, undef, '-s gind.ist'); }
# To run glo->gls we simply define a custom dependency rule:
add_cus_dep( "glo", "gls", 1, "glo2gls" );
sub glo2gls { return Run_subst( $makeindex, undef, '-s gglo.ist' ); }
push @generated_exts, "glo", "gls";


# Output files generated by the snapshot package.
push @generated_exts, "dep";

# Auxiliary files generated by the hypdoc package.
push @generated_exts, "hd";

# Auxiliary files generated by the tcolorbox package.
push @generated_exts, "listing";

