package Games::Traveller::UWP;

use 5.008003;
use strict;
use warnings;
use YAML;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( readUwp toString );
our $VERSION = '0.9';

###############################################################
#
#   Package Logic
#
###############################################################
{
   my @hex = ( 0..9, 'A'..'H', 'J'..'N', 'P'..'Z' );
   my %hex2dec = ();
   for( my $i=0; $i<@hex; $i++ )
   {
      $hex2dec{$hex[$i]} = "$i";
   }

   my %yaml = ();
   
   sub new { bless {}, shift }

   ###########################################################
   #
   #  Essential methods
   #
   #   readUwp()  - parses in the given UWP line data
   #
   #   toString() - prints data out in standard UWP format
   #
   ###########################################################

   sub readUwp
   {
      my $self = shift;
      my $line = shift;

      $yaml{+$self}->{data} = ();      
      $self->_oldUWP( $line ) 
         unless $self->_standardUWP( $line );
         
      return $self;
   }
   
   sub toString
   {
      my $self   = shift;
      my $routes = '';
      
      $routes = ' :' . join( ',', @{$self->routes} ) if $self->routes;
      
      return sprintf( "%-15s %04d %8s %s %-15s %s %s%s%s %2s %s%s\n",
             $self->name,
             $self->hex,
             $self->uwp,
             $self->bases,
             $self->codes,
             $self->zone,
             $self->popMult,
             $self->belts,
             $self->ggs,
             $self->allegiance,
             $self->stars,
             $routes );
   }
      
   ###########################################################
   #
   #  Read-write methods
   #
   ###########################################################
   
   sub _yaml         :lvalue { $yaml{+shift} }
   sub _src          :lvalue { $yaml{+shift}->{data}->{src}          }
   sub name          :lvalue { $yaml{+shift}->{data}->{Name}         }
   sub hex           :lvalue { $yaml{+shift}->{data}->{Hex}          }
   sub starport      :lvalue { $yaml{+shift}->{data}->{Starport}     }
   sub size          :lvalue { $yaml{+shift}->{data}->{Size}         }
   sub atmosphere    :lvalue { $yaml{+shift}->{data}->{Atmosphere}   }
   sub hydrographics :lvalue { $yaml{+shift}->{data}->{Hydrographics}}
   sub popDigit      :lvalue { $yaml{+shift}->{data}->{Population}   }
   sub government    :lvalue { $yaml{+shift}->{data}->{Government}   }
   sub law           :lvalue { $yaml{+shift}->{data}->{Law}          }
   sub tl            :lvalue { $yaml{+shift}->{data}->{TL}           }
   sub bases         :lvalue { $yaml{+shift}->{data}->{Bases}        }
   sub codes         :lvalue { $yaml{+shift}->{data}->{Codes}        }
   sub zone          :lvalue { $yaml{+shift}->{data}->{Zone}         }
   sub popMult       :lvalue { $yaml{+shift}->{data}->{PM}           }
   sub belts         :lvalue { $yaml{+shift}->{data}->{Belts}        }
   sub ggs           :lvalue { $yaml{+shift}->{data}->{GGs}          }
   sub allegiance    :lvalue { $yaml{+shift}->{data}->{Allegiance}   }
   sub starData      :lvalue { $yaml{+shift}->{data}->{Stellar}      }
   sub routes        :lvalue { $yaml{+shift}->{data}->{Routes}       }
   
   ###########################################################
   #
   #  Read-only methods
   #
   ###########################################################
   
   sub isBa($) { (population(shift) eq '0')            && 'Ba ' }
   sub isLo($) { (population(shift) =~ /0-4/)          && 'Lo ' }
   sub isHi($) { (population(shift) =~ /9A/)           && 'Hi ' }
   sub isAg($) { (uwp(shift) =~ /^..[4-9][4-8][5-7]/)  && 'Ag ' }
   sub isNa($) { (uwp(shift) =~ /^..[0-3][0-3][6-A]/)  && 'Na ' }
   sub isIn($) { (uwp(shift) =~ /^..[012479].[9A]/)    && 'In ' }
   sub isNi($) { (uwp(shift) =~ /^....[0-6]/)          && 'Ni ' }
   sub isRi($) { (uwp(shift) =~ /^..[6-8].[6-8][4-9]/) && 'Ri ' }
   sub isPo($) { (uwp(shift) =~ /^..[2-5][0-3][^0]/)   && 'Po ' }
   
   sub isWa($) { (hydrographics(shift) eq 'A')         && 'Wa ' }
   sub isDe($) { (uwp(shift) =~ /^..[2-A]0/)           && 'De ' }
   sub isAs($) { (size(shift) eq '0')                  && 'As ' }
   sub isVa($) { (uwp(shift) =~ /^..[1-A]0/)           && 'Va ' }
   sub isIc($) { (uwp(shift) =~ /^..[01][1-A]/)        && 'Ic ' }
   sub isFl($) { (uwp(shift) =~ /^..A[1-A]/)           && 'Fl ' }
   
   sub isCp($) { (codes(shift) =~ /cp/)                && 'Cp ' }
   sub isCx($) { (codes(shift) =~ /cx/)                && 'Cx ' }

   ############################################################
   #
   #   Returns the calculated population of the world.
   #
   ############################################################
   sub population($)
   {
      my $self = shift;
      return $self->popMult * (10 ** $hex2dec{ $self->popDigit } );
   }

   ############################################################
   #
   #  Returns the hex-row or hex-col coordinates of the world.
   #
   ############################################################   
   sub col($)     { (location(shift) =~ /^(..)/)[0] }
   sub row($)     { (location(shift) =~ /(..)$/)[0] }

   ############################################################
   #
   #  Returns the core UWP, i.e. A123456-7
   #
   ############################################################
   sub uwp($)
   {
      my $self = shift;
      return $self->starport . $self->size       . $self->atmosphere . $self->hydrographics
           . $self->popDigit . $self->government . $self->law . '-'  . $self->tl;
   }

   ############################################################
   #
   #  Converts star data back to string format.
   #   
   ############################################################
   sub stars($)
   {
      my $self    = shift;
      return '' unless $self->starData;
      my @stardat = @{$self->starData};
     
      my $primary = shift @stardat;
      my @primary = @$primary;
           
      my $out = '';
      
      $out = $primary[0]                       unless @primary > 1;
      $out = '(' . join( ' ', @primary ) . ')' if     @primary > 1;
      
      while ( @stardat && ref $stardat[0] ne 'ARRAY' )
      {
         $out .= ' ' . shift @stardat;
      }
      
      my $far = shift @stardat;
      
      if ( $far )
      {
         my @far = @$far;
         $out .= ' [';
         my $farpri = shift @far;
         my @farpri = @$farpri;
         
         $out .= $farpri[0]                       unless @farpri > 1;
         $out .= '(' . join( ' ', @farpri ) . ')' if     @farpri > 1;
         
         $out .= ' ' . join( ' ', @far )          if     @far;
         
         $out .= ']';
      }
      
      return $out;
   }

   ###########################################################
   #
   #  Estimate the importance of this world in the big 
   #  scheme of things.
   #
   ###########################################################
   
   sub importance($)
   {
      my $self = shift;
      my $importance = 0;
      
      $importance++ if $self->starport =~ /[AB]/;
      $importance-- if $self->starport =~ /[EX]/;
      $importance++ if $self->tl       !~ /\d/;
      $importance-- if $self->tl       =~ /[01235]/;
      
      $importance++ if $self->isHi();
      $importance-- if $self->isLo();
      $importance++ if $self->isRi();
      $importance-- if $self->isPo();
      $importance++ if $self->isAg();
      $importance++ if $self->isIn();
      
      $importance++ if $self->isCp() || $self->isCx();
      
      $importance = 0 if $importance < 0;
      
      return $importance;
   }

   ###########################################################
   #
   #  Return the number of billions of people here,
   #  or fraction thereof.
   #
   ###########################################################
   
   sub countBillionsOfPeople($)
   {
      my $self = shift;
      my $pm   = $self->popMult() || 1;
      
      return $pm * 10 if $self->popul eq 'A';
      return $pm      if $self->popul eq '9';
      return $pm/10   if $self->popul eq '8';
      return $pm/100  if $self->popul eq '7';
      return 0;
   }
   
   ###########################################################
   #
   #  Sort trade codes.
   #
   ###########################################################
   sub alphabetizeTradeCodes($)
   {
      my $self = shift;
      
      $self->codes = join( ' ', sort split( ' ', $self->codes ) );
   }
   
   ###########################################################
   #
   #  Determine trade codes.
   #
   #  Note: this will only potentially change trade codes
   #  that can be determined via the UWP.  Other codes are
   #  kept as-is.
   #
   ###########################################################
   sub regenerateTradeCodes($)
   {
      my $self = shift;
      my $s = '';
                  
      $self->codes =~ s/(Ba|Lo|Hi|Ag|Na|In|Ni|Ri|Po|Wa|De|As|Va|Ic|Fl)\s*//g;      
      
      $s .= $self->isBa || $self->isLo || $self->isHi || '';
      $s .= $self->isAg || $self->isNa || '';
      $s .= $self->isIn || $self->isNi || '';
      $s .= $self->isRi || $self->isPo || '';
      $s .= $self->isWa || $self->isDe || '';
      $s .= $self->isAs || $self->isVa || '';
      $s .= $self->isIc || $self->isFl || '';
      
      $self->codes = $s . $self->codes;
      
      return $self;
   } 
   
   ###########################################################
   #
   #  Internal functions
   #
   ###########################################################
   
   sub DESTROY             { delete $yaml{+shift} }

   sub _standardUWP($$)
   {
      my $self = shift;
      my $line = shift;
      
      if ( $line =~ /^\s*(\S.+\S)?    # name
                      \s*(\d{4})      # hex
                      \s+(\w\w{6}-\w) # uwp
                      \s+(.*)         # codes
                      \s+(\d{3})      # PBG
                      \s+(\w\w)       # allegience
                      \s+(.*)         # star data, etc
                      \s*
                    $/x )
      {
         $self->_src = 'Std';
         $self->name = $1;
         $self->hex  = $2;
         
         $self->_loadUwp( $3 );
         $self->_loadCodes( $4 );
         $self->_loadPBG( $5 );
         
         $self->allegiance = $6;
         $self->_loadStars( $7 );
         
         return $self;
      }      
      return ();
   }
   
   sub _oldUWP($$)
   {
      my $self = shift;
      my $line = shift;
      
      if ( $line =~ /^\s*(\S.*\S)?      # name
                      \s*(\d{4})        # hex
                      \s+(\w\w{6}-\w)   # uwp
                      \s*(.*)           # codes
                    /x )
      {
         $self->_src = 'Old';
         $self->name = $1;
         $self->hex  = $2;
         
         $self->_loadUwp( $3 );
         
         my @codes = split( ' ', $4 );
         my $gg = pop @codes if $codes[-1] eq 'G';
         
         $self->_loadCodes( join( ' ', @codes ) ); 
        
         $self->popMult = 5;
         $self->belts   = 0;
         $self->ggs     = 0;
         $self->ggs     = 1 if $gg;
         
         $self->allegiance = 'Un';
      }
      return ();
   }
   
   sub _loadUwp
   {
      my $self   = shift;
      my $uwp    = shift;
      my $dash;
      
      ($self->starport,
       $self->size,
       $self->atmosphere,
       $self->hydrographics,
       $self->popDigit,
       $self->government,
       $self->law,
       $dash,
       $self->tl) = split( '', $uwp );
   }
   
   sub _loadCodes
   {
      my $self   = shift;
      my $codes  = shift;
      my @codes  = split( ' ', $codes );
      my $bases  = shift @codes if length( $codes[0]  ) == 1;
      my $zone   = pop   @codes if length( $codes[-1] ) == 1;
      
      $self->bases = $bases;
      $self->codes = join( ' ', @codes );
      $self->zone  = $zone;
   }
   
   sub _loadPBG
   {
      my $self = shift;
      my $pbg  = shift;
      
      ($self->popMult,
       $self->belts,
       $self->ggs) = split( '', $pbg );
   }

   sub _loadStars
   {
      my $self  = shift;
      my $stuff = shift;
      my ($stars, $routes) = split( ':', $stuff );
    
      $self->_loadRoutes( $routes ) if $routes;
             
      return unless $stars;
      
      # force all primary stars to be nested
      $stars =~ s/ \[(\w+ \w+)/ [[$1]/;
      $stars =~ s/^(\w+ \w+)/[$1]/;

      # translate all parens to brackets
      $stars =~ tr/\(\)/\[\]/;
      
      # add commas
      $stars =~ s/\] /\], /g;
      $stars =~ s/(\w+ \w+) /$1, /g;
      
      $stars =~ s/^(....*)$/[$1]/;
      
      my $stardat = YAML::Load( "--- \n stars: $stars\n" );
      
      $self->starData = $stardat->{stars};
   }
   
   sub _loadRoutes
   {
      my $self   = shift;
      my $routes = shift;
      my @routes = split( ',', $routes );
      $self->routes = \@routes;
   }
}
1;

__END__

=head1 NAME

Games::Traveller::UWP - The Universal World Profile parser for the Traveller role-playing game.

=head1 SYNOPSIS

   use Games::Traveller::UWP;
   
   print "This is UWP $Games::Traveller::UWP::VERSION\n";

   my $uwp = new Games::Traveller::UWP;
   
   my $line  = "My World  0980 X123456-8 N  Ri Ag Cp         R G";

   $uwp->readUwp( $line );

   print $uwp->toString();

   $uwp->readUwp( 'Foo  1010 A123456-7 B Ri In Da Na R 232 Im K0 V [(G5 D G6 D)] :1010, 1011, 1012' );

   print $uwp->toString();

=head1 DESCRIPTION

The UWP package is a module that provides access to UWP data by parsing
a valid UWP line, stored in a scalar string.  The data is parsed and made
available to the user via a rich set of accessors, some of which are usable
as L-values (but most are read-only).

=head1 OVERVIEW OF CLASS AND METHODS

To create an instance of a UWP:

   my $uwp = new Games::Traveller::UWP;

The following accessors can be either RValues (read) or LValues (write):

=over 3

   $uwp->name       
   $uwp->hex        
   $uwp->starport   
   $uwp->size
   $uwp->atmosphere
   $uwp->hydrographics
   $uwp->popDigit
   $uwp->government
   $uwp->law
   $uwp->tl
   $uwp->bases
   $uwp->codes
   $uwp->zone
   $uwp->popMult
   $uwp->belts
   $uwp->ggs
   $uwp->allegiance
   $uwp->starData (an array ref)
   $uwp->routes (an array ref)
   
=back
   
In addition to the above, there is a large body of read-only accessors:

=over 3

   $uwp->population # calculates the population from the popDigit and popMult
   $uwp->col        # returns the column component of the hex location
   $uwp->row        # ibid for the row
   $uwp->uwp        # returns the core UWP (i.e. "A123456-7")
   $uwp->stars      # returns the standard star data string
   $uwp->importance # calculates how important the world probably is

   $uwp->countBillionsOfPeople  # returns the population in billions

   $uwp->alphabetizeTradeCodes
   
   $uwp->regenerateTradeCodes  # re-does trade codes

   The previous method is useful if you've been changing the UWP values around.


   $uwp->isBa       # returns 'Ba' if the world is Barren
   $uwp->isLo       # returns 'Lo' if the world is Low-Pop
   $uwp->isHi       # high pop
   $uwp->isAg       # agricultural
   $uwp->isNa       # non-agri
   $uwp->isIn       # industrial
   $uwp->isNi       # non-ind
   $uwp->isRi       # rich
   $uwp->isPo       # poor
   $uwp->isWa       # water world
   $uwp->isDe       # desert
   $uwp->isAs       # mainworld is asteroid
   $uwp->isVa       # vacuum world
   $uwp->isIc       # all water is ice
   $uwp->isFl       # non-water fluid oceans
   
   $uwp->isCp       # subsector capital
   $uwp->isCx       # sector capital
 

=back
   
   Finally, 
   
=over 3

   $uwp->toString 

=back
   
   returns the UWP data encapsulated in a string, suitable for writing to
   an output stream.
   
=head1 AUTHOR

  Pasulii Immuguna

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN.

=cut
