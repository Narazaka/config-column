package Config::Column;
use utf8;
# use strict;
# use warnings;

our $VERSION = '2.00';

=encoding utf8

=head1 NAME

Config::Column - simply packages input and output of column oriented data files such as "BBS log file" etc. whose records are separated by any delimiter.

=head1 SYNOPSIS

	# Copy the data_list in a tab separated file to readable formatted text file.
	
	use utf8;
	use lib './lib';
	use Config::Column;
	my $order_delim = [qw(1 subject date value)];
	my $order_nodelim = ['' => 1 => ': [' => subject => '] ' => date => ' : ' => value => ''];
	my $delimiter = "\t";
	
	# MAIN file instance
	my $ccmain = Config::Column->new(
		'mainfile.dat', # the data file path
		'utf8', # character encoding of the data file (PerlIO ":encoding($layer)") or PerlIO layer (ex. ':encoding(utf8)') 
		$order_delim, # list of key names
		$delimiter, # delimiter that separates data column
		1, # first index for data list
		"\0" # delimiter that separates data record ("lines")
	);
	# SUB file (human readable)
	my $ccsub = Config::Column->new(
		'', # this can be empty because data file will be opened externally and file handle is passed to this instance
		'', # same reason
		$order_nodelim, # list of key names and delimiters
		undef, # do not define delimiter
		1, # first index for data list
		# delimiter that separates data record ("lines") is Default
	);
	
	# Read data from MAIN file.
	my $data = $ccmain->read_data;
	# Add new data.
	push @$data,{subject => 'YATTA!', date => '2012/03/06T23:33:00+09:00', value => 'All tests passed!'};print $data;
	# Write data to MAIN file.
	$ccmain->write_data($data);
	# Write header to SUB file
	open my $file_handle,'+<:encoding(utf8)','subfile.txt';
	flock $file_handle,2;
	truncate $file_handle,0;
	seek $file_handle,0,0;
	print $file_handle 'Single line diary?',"\n";
	# Add data to SUB file. Don't close and don't truncate $file_handle.
	$ccsub->write_data($data,$file_handle,1,1);
	print $file_handle 'The end of the worl^h^h^h^hfile';
	close $file_handle;

=head1 INTRODUCTION

This module generalizes input and output of column oriented data files such as "config file" / "BBS log file".

Here is an example of column oriented data format (tab separated data).

	1	title1	new
	2	title2	second season
	3	title3	mannerism
	5	title5	never 4th season

This module treats data list as simple array reference of hash references.

	my $data_list = [
		{}, # If the first index for data list (see below section) is 1, 0th data is empty.
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];

It manages only IO of that data list format and leaves data list manipulating to basic Perl operation.

=head1 DESCRIPTION

=head2 Constructor

=head3 new()

	my $cc = Config::Column->new(
		$datafile, # the data file path
		$layer, # character encoding of the data file (PerlIO ":encoding($layer)") or PerlIO layer (ex. ':encoding(utf8)') 
		$order, # the "order" (see below section) (ARRAY REFERENCE)
		$delimiter, # delimiter that separates data column
		$index_shift, # first index for data list (may be 0 or 1 || can omit, and use 0 as default) (Integer >= 0)
		$record_delimiter, # delimiter that separates data record ("lines")(can omit, and use Perl default (may be $/ == "\n"))
		$escape # escape character for delimiters (including $record_delimiter)
	);

or with names,

	my $cc = Config::Column->new({
		datafile => $datafile,
		layer => $layer,
		order => $order,
		delimiter => $delimiter,
		index_shift => $index_shift,
		record_delimiter => $record_delimiter,
		escape => $escape
	});

C<$index_shift> is 0 or 1 in general.
For example, if C<$index_shift == 1>, you can get first data record by accessing to C<< $data_list->[1] >>, and C<< $data_list->[0] >> is empty.

If you have defined C<$escape>, the delimiter strings in the data list are automatically escaped.
Two or more characters are permitted for C<$escape>, but if you want to use C<$escape>, delimiters should not be part of C<$escape>.

	{
		# orthodox
		my $escape = "\\";
		my $delimiter = "\t";
		my $line_delimiter = "\n";
	}
	{
		# long
		my $escape = "--";
		my $delimiter = "//";
		my $line_delimiter = "||";
	}
	{
		# delimiters are not part of $escape
		my $escape = "aa";
		my $delimiter = "aaaa";
		my $line_delimiter = "\n";
	}
	{
		# FAIL: $delimiter is part of $escape
		my $escape = "aaaa";
		my $delimiter = "aa";
		my $line_delimiter = "\n";
	}

There is two types of definition of C<$order> and C<$delimiter> for 2 following case.

=over

=item single delimiter (You must define delimiter.)

	my $cc = Config::Column->new(
		'./file.dat', # the data file path
		'utf8', # character encoding of the data file or PerlIO layer
		[qw(1 author id title date summary)], # the "order" [keys]
		"\t", # You MUST define delimiter.
		1, # first index for data list
		"\n", # delimiter that separates data record
		"\\" # escape character for delimiters
	);

In this case, "order" is names (hash keys) of each data column.

It is for data formats such as tab/comma separated data.

=item multiple delimiters (Never define delimiter.)

	my $cc = Config::Column->new(
		'./file.dat', # the data file path
		'utf8', # character encoding of the data file or PerlIO layer
		[qw('' 1 ': ' author "\t" id "\t" title "\t" date "\t" summary)], # [delim key delim key ...]
		undef, # NEVER define delimiter (or omit).
		1, # first index for data list
		"\n", # delimiter that separates data record
		"\\" # escape character for delimiters
	);

In this case, "order" is names (hash keys) of each data column and delimiters.

C<$order>'s 0,2,4...th (even) elements are delimiter, and 1,3,5...th (odd) elements are names (hash keys).

It is for data formats such as ...

=over

=item C<['', 1, ' [', subject, '] : ', date, ' : ', article]>

	1 [This is the subject] : 2012/02/07 : Article is there. HAHAHA!
	2 [Easy to read] : 2012/02/07 : Tab separated data is for only computers.

=item C<< ['', thread_number, '.dat<>', subject, ' (', res_number, ')'] # subject.txt (bracket delimiter is errorous) >>

	1325052927.dat<>Nurupo (988)
	1325387590.dat<>OKOTOWARI!!!!!! Part112 [AA] (444)
	1321698127.dat<>Marked For Death 18 (159)

=back

=back

=head4 Index column

The name "1" in C<$order> means the index of data records.

If the name "1" exists in C<$order>, integer in the index column will be used as array references' index.

	$delimiter = "\t";
	$order = [1,somedata1,somedata2];
	
	# data file
	1	somedata	other
	2	foobar	2000
	3	hoge	piyo
	5	English	isDifficult
	
	 |
	 | read_data()
	 v
	
	$data_list = [
		{}, # 0
		{somedata1 => 'somedata', somedata2 => 'other'}, # 1
		{somedata1 => 'foobar', somedata2 => '2000'}, # 2
		{somedata1 => 'hoge', somedata2 => 'piyo'}, # 3
		{}, # 4
		{somedata1 => 'English', somedata2 => 'isDifficult'}, # 5
	];
	
	 |               ^
	 | write_data()  | read_data()
	 v               |
	
	# data file
	1	somedata	other
	2	foobar	2000
	3	hoge	piyo
	4		
	5	English	isDifficult

=begin comment

#=head3 Definition of delimiters

C<$delimiter> is compiled to regular expressions finally.

In case of single delimiter,

	my @column = split /$delimiter/,$recordline;

In case of multiple delimiters, C<$record_delimiter> is also compiled to regular expressions.

	my $record_regexp_str = '^'.(join '(.*?)',map {quotemeta} @delimiters) . '(?:' . quotemeta($record_delimiter) . ')?$';
	my $record_regexp = qr/$record_regexp_str/;

=end comment

=cut

sub new{
	my $package = shift;
	$package = ref $package || $package;
	my ($file, $layer, $order, $delimiter, $index_shift, $record_delimiter, $escape);
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$file = $option->{file} || $option->{file_name} || $option->{filename};
		$layer = $option->{layer};
		$order = $option->{order};
		$delimiter = $option->{delimiter};
		$index_shift = $option->{index_shift};
		$record_delimiter = $option->{record_delimiter};
		$escape = $option->{escape};
	}else{
		$file = shift;
		$layer = shift;
		$order = shift;
		$delimiter = shift;
		$index_shift = shift;
		$record_delimiter = shift;
		$escape = shift;
	}
	$index_shift = 0 unless $index_shift;
	die 'invalid index_shift (not number)' unless $index_shift =~ /^\d+$/;
	return bless {
		file => $file,
		layer => $layer,
		order => $order,
		delimiter => $delimiter,
		index_shift => $index_shift,
		record_delimiter => $record_delimiter,
		escape => $escape
	},$package;
}

=head2 Methods

=head3 add_data_last()

This method adds data records to the data file after previous data in the file.
Indexes of these data records are automatically setted by reading the data file before.

	$cc->add_data_last($data,$file_handle,$keep_file_handle);

	my $data = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	]; # hash reference of single data record or array reference of hash references of multiple data records
	my $file_handle; # file handle (can omit)
	my $keep_file_handle = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and adds data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: 1 , second: (if C<$keep_file_handle> is true) file handle

Fail > first: false (return;)

=cut

sub add_data_last{
	my $self = shift;
	my ($data_list, $file_handle, $keep_file_handle);
	if(ref $_[0] eq 'HASH' && ref $_[0]->{data_list}){
		my $option = shift;
		$data_list = $option->{data_list};
		$file_handle = $option->{file_handle} || $option->{fh};
		$keep_file_handle = $option->{keep_file_handle} || $option->{fhflag};
	}else{
		$data_list = shift;
		$file_handle = shift;
		$keep_file_handle = shift;
	}
	$data_list = [$data_list] if ref $data_list eq 'HASH';
	my $data_num;
	($data_num,$file_handle) = $self->read_data_num($file_handle,1);
	return $self->add_data($data_list,$data_num + 1,$file_handle,$keep_file_handle);
}

=head3 add_data()

This method adds data records to the data file.

	$cc->add_data($data_list,$start_index,$file_handle,$keep_file_handle);

	my $data_list = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	]; # hash reference of single data record or array reference of hash references of multiple data records
	my $start_index = 12; # first index of the data record (can omit if you don't want index numbers)
	my $file_handle; # file handle (can omit)
	my $keep_file_handle = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and adds data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: 1 , second: (if C<$keep_file_handle> is true) file handle

Fail > first: false (return;)

=cut

sub add_data{
	my $self = shift;
	my ($data_list, $start_index, $file_handle, $keep_file_handle);
	if(ref $_[0] eq 'HASH' && ref $_[0]->{data_list}){
		my $option = shift;
		$data_list = $option->{data_list};
		$start_index = $option->{start_index};
		$file_handle = $option->{file_handle} || $option->{fh};
		$keep_file_handle = $option->{keep_file_handle} || $option->{fhflag};
	}else{
		$data_list = shift;
		$start_index = shift;
		$file_handle = shift;
		$keep_file_handle = shift;
	}
	$data_list = [$data_list] if ref $data_list eq 'HASH';
	unless(ref $file_handle eq 'GLOB'){
		my $layer = $self->_layer();
		open $file_handle,'+<'.$layer,$self->{file} or open $file_handle,'>'.$layer,$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $file_handle,2;
		seek $file_handle,0,2;
	}
	$self->_write_order($file_handle,$data_list,$start_index);
	close $file_handle unless $keep_file_handle;
	return $keep_file_handle ? (1,$file_handle) : 1;
}

=head3 write_data()

This method writes data records to the data file.
Before writing data, the contents of the data file will be erased.

	$cc->write_data($data_list,$file_handle,$keep_file_handle,$no_empty);

	my $data_list = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	]; # array reference of hash references of multiple data records
	my $file_handle; # file handle (can omit)
	my $keep_file_handle = 1; # if true, file handle will not be closed (can omit)
	my $no_empty = 1; # see below

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle.
If C<$no_empty> is true, the contents of the data file will not be erased, and writes data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: 1 , second: (if C<$keep_file_handle> is true) file handle

Fail > first: false (return;)

=cut

sub write_data{
	my $self = shift;
	my ($data_list, $file_handle, $keep_file_handle, $no_empty);
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$data_list = $option->{data_list};
		$file_handle = $option->{file_handle} || $option->{fh};
		$keep_file_handle = $option->{keep_file_handle} || $option->{fhflag};
		$no_empty = $option->{no_empty};
	}else{
		$data_list = shift;
		$file_handle = shift;
		$keep_file_handle = shift;
		$no_empty = shift;
	}
	$data_list = [@{$data_list}]; # escape destructive operation
	splice @$data_list,0,$self->{index_shift};
	unless(ref $file_handle eq 'GLOB'){
		my $layer = $self->_layer();
		open $file_handle,'+<'.$layer,$self->{file} or open $file_handle,'>'.$layer,$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $file_handle,2;
	}
	unless($no_empty){
		truncate $file_handle,0;
		seek $file_handle,0,0;
	}
	return $self->add_data($data_list,$self->{index_shift},$file_handle,$keep_file_handle);
}

=begin comment

#=head3 write_data_range()

範囲内のデータをファイルに書き出す。

	$cc->write_data_range($data_list,$start_index,$endindex,$file_handle,$keep_file_handle);

	my $data_list = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];# 複数データの配列リファレンスのみ許される。
	my $start_index = 2; # 書き出すデータリストの最初のインデックス。0番目のデータから書き出すなら省略可能。
	my $endindex = 10; # 書き出すデータリストの最後のインデックス。最後のデータまで書き出すなら省略可能。
	my $file_handle; # 省略可能。ファイルハンドル。
	my $keep_file_handle = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

成功なら第一返値に1、$keep_file_handleが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=end comment

=cut

=begin comment

sub write_data_range{
	my $self = shift;
	my $data_list = shift;
	my $start_index = shift;
	my $endindex = shift;
	my $file_handle = shift;
	my $keep_file_handle = shift;
	$data_list = [@{$data_list}]; # escape destructive operation
	if($start_index){
		$start_index = $#$data_list + $start_index + 1 if $start_index < 0;
		if($start_index > $#$data_list){
			warn 'start_index is out of index range';
		}
	}else{
		$start_index = $self->{index_shift};
	}
	splice @$data_list,0,$start_index > $self->{index_shift} ? $start_index : $self->{index_shift};
	if($endindex){
		$endindex = $#$data_list + $endindex + 1 if $endindex < 0;
		if($endindex > $#$data_list){
			warn 'endindex is out of index range';
		}elsif($endindex < $#$data_list){
			splice @$data_list,$endindex + 1;
		}
	}
	return $self->add_data($data_list,$start_index,$file_handle,$keep_file_handle);
}

=end comment

=cut

=head3 read_data()

This method reads data records from the data file.

	$cc->read_data($file_handle,$keep_file_handle);

	my $file_handle; # file handle (can omit)
	my $keep_file_handle = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and reads data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: data list (array reference of hash references) , second: (if C<$keep_file_handle> is true) file handle

Fail > first: false (return;)

=cut

sub read_data{
	my $self = shift;
	my ($file_handle, $keep_file_handle);
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$file_handle = $option->{file_handle} || $option->{fh};
		$keep_file_handle = $option->{keep_file_handle} || $option->{fhflag};
	}else{
		$file_handle = shift;
		$keep_file_handle = shift;
	}
	unless(ref $file_handle eq 'GLOB'){
		open $file_handle,'+<'.$self->_layer(),$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $file_handle,2;
		seek $file_handle,0,0;
	}
	my $data = $self->_read_order($file_handle);
	close $file_handle unless $keep_file_handle;
	return $keep_file_handle ? ($data,$file_handle) : $data;
}

=head3 read_data_num()

This method reads data record's last index number from the data file.

	$cc->read_data_num($file_handle,$keep_file_handle);

	my $file_handle; # file handle (can omit)
	my $keep_file_handle = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and reads data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: last index , second: (if C<$keep_file_handle> is true) file handle

Fail > first: false (return;)

=cut

sub read_data_num{
	my $self = shift;
	my ($file_handle, $keep_file_handle);
	if(ref $_[0] eq 'HASH'){
		my $option = shift;
		$file_handle = $option->{file_handle} || $option->{fh};
		$keep_file_handle = $option->{keep_file_handle} || $option->{fhflag};
	}else{
		$file_handle = shift;
		$keep_file_handle = shift;
	}
	unless(ref $file_handle eq 'GLOB'){
		open $file_handle,'+<'.$self->_layer(),$self->{file} or die 'cannot open file [',$self->{file},']';
		flock $file_handle,2;
		seek $file_handle,0,0;
	}
	local $/ = $self->{record_delimiter} if defined $self->{record_delimiter} && $self->{record_delimiter} ne '';
	my $data_num = $self->{index_shift} - 1;
	if($self->{delimiter}){
		my $index_column = -1;
		for my $i (0..$#{$self->{order}}){
			if($self->{order}->[$i] eq 1){$index_column = $i;last;}
		}
		if($index_column < 0){$data_num++ while <$file_handle>;}
		else{$data_num = (split /$self->{delimiter}/)[$index_column] while <$file_handle>;}
		chomp $data_num;
	}else{
		my @key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $record_regexp_str = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		my $record_regexp = qr/$record_regexp_str/;
		my $index_column = -1;
		for my $i (0..$#key){
			if($key[$i] eq 1){$index_column = $i;last;}
		}
		if($index_column < 0){$data_num++ while <$file_handle>;}
		else{$data_num = (/$record_regexp/)[$index_column] while <$file_handle>;}
	}
	close $file_handle unless $keep_file_handle;
	return $keep_file_handle ? ($data_num,$file_handle) : $data_num;
}

=begin comment
### escaping read
my $esc = '   ';
my $escreg = quotemeta $esc;
my $delim = "\"";
my $delimreg = quotemeta $delim;
my $str1 = "start${delim}d:ads?a${esc}${delim}adada${esc}${esc}sda${esc}${delim}${esc}${esc}${esc}${esc}${delim}";
my $str2 = "start${delim}dadsa?${esc}${esc}${esc}${delim}adada\sda${esc}${esc}${esc}${delim}${delim}end${delim}";
print '1 : ',$str1,"\n";
print '2 : ',$str2,"\n";
#print 'e1: ',eval $str1,"\n";
#print 'e2: ',eval $str2,"\n";
$reg = qr/$delimreg((?:$escreg$escreg|$escreg$delimreg|[^$delimreg])*)$delimreg/;
print $reg,"\n";
print join ' / ',$str1 =~ $reg,"\n";
print join ' / ',$str2 =~ $reg,"\n";
=end comment

=begin comment

#=head3 _write_order()

	$cc->_write_order($order,$delimiter,$record_delimiter);
	$order = [1 title summary];
	$delimiter = "\n";
	$record_delimiter = "\n";

=end comment

=cut

sub _write_order{
	my $self = shift;
	my $file_handle = shift;
	my $data_list = shift;
	my $index = shift;
	my $delimiter = $self->{delimiter};
	my @order = @{$self->{order}};
	local $/ = $self->{record_delimiter} if defined $self->{record_delimiter} && $self->{record_delimiter} ne '';
	if(defined $self->{delimiter} && $self->{delimiter} ne ''){ # has delimiter
		for my $data (@$data_list){
			print $file_handle (join $delimiter,map {$_ eq 1 ? $index : defined $data->{$_} ? $data->{$_} : ''} @order),$/;
			$index ++;
		}
	}else{ # no delimiter
		for my $data (@$data_list){
			print $file_handle (map {$_ % 2 ? $order[$_] eq 1 ? $index : defined $data->{$order[$_]} ? $data->{$order[$_]} : '' : $order[$_]} (0..$#order)),$/;
			$index ++;
		}
	}
}

sub _read_order{
	my $self = shift;
	my $file_handle = shift;
	my @key;
	my $record_regexp;
	local $/ = $self->{record_delimiter} if defined $self->{record_delimiter} && $self->{record_delimiter} ne '';
	my $d_mode;
	if(defined $self->{delimiter} && $self->{delimiter} ne ''){ # has delimiter
		$d_mode = 1;
		@key = @{$self->{order}};
	}else{ # no delimiter
		$d_mode = 0;
		@key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $record_regexp_str = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		$record_regexp = qr/$record_regexp_str/;
	}
	my $index_column = -1;
	my $key_column = -1;
	my @ref_column = 0..$#key;
	for my $i (0..$#key){
		if($key[$i] eq 1){
			$index_column = $i;
			last;
		}elsif($key[$i] eq '0'){
			$key_column = $i;
			last;
		}
	}
	my ($c,$k);
	my $ik_mode;
	if($key_column != -1){
		splice @ref_column, $key_column, 1;
		$ik_mode = 2;
	}elsif($index_column != -1){
		splice @ref_column, $index_column, 1;
		$ik_mode = 1;
	}else{
		$c = $self->{index_shift} - 1;
		$ik_mode = 0;
	}
	my $data;
	while(<$file_handle>){
		chomp;
		my @column = $d_mode ? split /$self->{delimiter}/ : /$record_regexp/;
		if($ik_mode == 2){
			$k = $column[$key_column];
			$data->{$k}->{$key[$_]} = $column[$_] for @ref_column;
		}elsif($ik_mode == 1){
			$c = $column[$index_column];
			$data->[$c]->{$key[$_]} = $column[$_] for @ref_column;
		}else{
			$c++;
			$data->[$c]->{$key[$_]} = $column[$_] for @ref_column;
		}
	}
	return $data;
}

sub _layer{
	my $self = shift;
	return $self->{layer} ? $self->{layer} =~ /:/ ? $self->{layer} : ':encoding('.$self->{layer}.')' : '';
}

1;

=head1 DEPENDENCIES

This module requires no other modules and libraries.

=head1 NOTES

=head2 OOP

This module is written in object-oriented style but treating data by naked array or file handle so you should treat data by procedural style.

For example, if you want to delete 3,6 and 8th element in data list completely, the following code will be required.

	splice @$data_list,$_,1 for sort {$b <=> $a} qw(3 6 8);

So, if you want more smart OO, it will be better to use another modules that wraps naked array or file handle in OO (such as Object::Array ... etc?), or create Config::Column::OO etc. which inherits this module and can use methods pop, shift, splice, delete, etc.

=head2 escaping

I think current implement of the regexp of escaping (includes slow (..|..|..)) is not the best.

=head2 For legacy system

Perl <= 5.6.x does not have PerlIO.
C<$layer> of this module is for character encoding and depends on PerlIO, so you should empty C<$layer> on Perl 5.6.x or older

=head1 TODO

Odd Engrish

=head1 AUTHOR

Narazaka (http://narazaka.net/)

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2012 by Narazaka, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
