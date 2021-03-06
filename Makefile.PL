use inc::Module::Install;

name 'Kindlenap';

version '0.02';
license 'perl';

requires 'Mouse';
requires 'MouseX::Types::URI';
requires 'MouseX::Types::Path::Class';
requires 'MouseX::Getopt';

requires 'autodie';
requires 'opts';

requires 'Class::Load';
requires 'Encode';
requires 'Encode::Guess';
requires 'Encode::Locale';
requires 'File::Basename';
requires 'File::Util';
requires 'FindBin';
requires 'HTML::Entities';
requires 'HTML::TreeBuilder::XPath';
requires 'HTTP::Config';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'HTML::HeadParser';
requires 'HTML::ExtractContent';
requires 'URI';
requires 'URI::QueryParam';
requires 'WWW::Mechanize', '1.50';
requires 'WWW::Mechanize::AutoPager';

auto_include;

WriteAll;
