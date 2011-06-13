use inc::Module::Install;

name 'Kindlenap';

version '0.01';
license 'perl';

requires 'Class::Load';
requires 'Encode';
requires 'Encode::Guess';
requires 'Encode::Locale';
requires 'File::Basename';
requires 'File::Util';
requires 'HTML::Entities';
requires 'HTML::TreeBuilder::XPath';
requires 'HTTP::Config';
requires 'JSON::XS';
requires 'LWP::UserAgent';
requires 'List::MoreUtils';
requires 'Mouse';
requires 'URI';
requires 'URI::QueryParam';
requires 'autodie';

auto_include;

WriteAll;
