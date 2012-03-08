package Config::Column;
use utf8;

our $VERSION = '1.00';

=encoding utf8

=head1 NAME

Config::Column - simply packages input and output of "config" / "BBS log" file whose records are separated by any delimiter.

=head1 SYNOPSIS

	# Copy the datalist in a tab separated file to readable formatted text file.
	
	use utf8;
	use lib './lib';
	use Config::Column;
	my $order_delim = [qw(1 subject date value)];
	my $order_nodelim = ['' => 1 => ': [' => subject => '] ' => date => ' : ' => value => ''];
	my $delimiter = "\t";
	
	# MAIN file instance
	my $ccmain = Config::Column->new(
		'mainfile.dat', # data file
		'utf8', # data file encoding
		$order_delim, # list of key names
		$delimiter, # delimiter of records
		1, # index offset
		"\0" # delimiter of "lines"
	);
	# SUB file (human readable)
	my $ccsub = Config::Column->new(
		'', # this can be empty because data file will be opened externally and file handle is passed to this instance
		'', # same reason
		$order_nodelim, # list of key names
		undef, # do not define delimiter
		1, # index offset
		# delimiter of "lines" is Default
	);
	
	# Read data from MAIN file.
	my $data = $ccmain->readdata;
	# Add new data.
	push @$data,{subject => 'YATTA!', date => '2012/03/06T23:33:00+09:00', value => 'All tests passed!'};print $data;
	# Write data to MAIN file.
	$ccmain->writedata($data);
	# Write header to SUB file
	open my $fh,'+<:encoding(utf8)','subfile.txt';
	flock $fh,2;
	truncate $fh,0;
	seek $fh,0,0;
	print $fh 'Single line diary?',"\n";
	# Add data to SUB file. Don't close and don't truncate $fh.
	$ccsub->writedata($data,$fh,1,1);
	print $fh 'The end of the worl^h^h^h^hfile';
	close $fh;

=head1 INTRODUCTION

This module generalizes the list of keys and delimiters that is common in "config" / "BBS log" file format and packageizes data list input and output of these files.

It treats data list as simple array reference of hash references.

	my $datalist = [
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
		$encoding, # character encoding of the data file (PerlIO ":encoding($encoding)")
		$order, # the "order" (see below section) (ARRAY REFERENCE)
		$delimiter, # delimiter that separates data column
		$indexshift, # first index for data list (may be 0 or 1 || can omit, and use 0 as default) (Integer >= 0)
		$linedelimiter # delimiter that separates data record ("lines")(can omit, and use Perl default (may be $/ == "\n"))
	);

C<$indexshift> is 0 or 1 in general.
For example, if C<$indexshift == 1>, you can get first data record by accessing to C<< $datalist->[1] >>, and C<< $datalist->[0] >> is empty.

There is two types of definition of C<$order> and C<$delimiter> for 2 following case.

=over

=item single delimiter (You must define delimiter.)

	my $cc = Config::Column->new(
		'./filename.dat', # the data file path
		'utf8', # character encoding of the data file
		[qw(1 author id title date summary)], # the "order" [keys]
		"\t", # You MUST define delimiter.
		1, # first index for data list
		"\n" # delimiter that separates data record
	);

In this case, "order" is names (hash keys) of each data column.

It is for data formats such as tab/comma separated data.

=item multiple delimiters (Never define delimiter.)

	my $cc = Config::Column->new(
		'./filename.dat', # the data file path
		'utf8', # character encoding of the data file
		[qw('' 1 ': ' author "\t" id "\t" title "\t" date "\t" summary)], # [delim key delim key ...]
		undef, # NEVER define delimiter (or omit).
		1, # first index for data list
		"\n" # delimiter that separates data record
	);

In this case, "order" is names (hash keys) of each data column and delimiters.

C<$order>'s 0,2,4...th (even) elements are delimiter, and 1,3,5...th (odd) elements are names (hash keys).

It is for data formats such as ...

=over

=item C<['', 1, ' [', subject, '] : ', date, ' : ', article]>

	1 [This is the subject] : 2012/02/07 : Article is there. HAHAHA!
	2 [Easy to read] : 2012/02/07 : Tab separated data is for only computers.

=item C<< ['', thread_number, '.dat<>', subject, ' (', res_number, ')'] # subject.txt (bracket delimiter is errorous) >>

	1325052927.dat<>ぬるぽのガイドライン 149ぬるぽ (988)
	1325387590.dat<>【巨大文字】お断りだのガイドラインPart112【AA】 (444)
	1318831084.dat<>スカッっとするコピペを貼るスレ　32スカッシュ (904)
	1321698127.dat<>死亡フラグのガイドライン　18フラグ目 (159)

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
	 | readdata()
	 V
	
	$datalist = [
		{}, # 0
		{somedata1 => 'somedata', somedata2 => 'other'}, # 1
		{somedata1 => 'foobar', somedata2 => '2000'}, # 2
		{somedata1 => 'hoge', somedata2 => 'piyo'}, # 3
		{}, # 4
		{somedata1 => 'English', somedata2 => 'isDifficult'}, # 5
	];
	
	 |              ^
	 | writedata()  | readdata()
	 V              |
	
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

In case of multiple delimiters, C<$linedelimiter> is also compiled to regular expressions.

	my $lineregexpstr = '^'.(join '(.*?)',map {quotemeta} @delimiters) . '(?:' . quotemeta($linedelimiter) . ')?$';
	my $lineregexp = qr/$lineregexpstr/;

=end comment

=cut

sub new{
	my $package = shift;
	my $filename = shift;
	my $encoding = shift;
	my $order = shift;
	my $delimiter = shift;
	my $index = shift;
	my $linedelimiter = shift;
	$package = ref $package || $package;
	$index = 0 unless $index;
	return unless $index =~ /^\d+$/;
	return bless {
		filename => $filename,
		encoding => $encoding,
		order => $order,
		delimiter => $delimiter,
		index => $index,
		linedelimiter => $linedelimiter,
		writeorder => _setwriteorder($order,$delimiter,$linedelimiter)
	},$package;
}

=head2 Methods

=head3 adddatalast()

This method adds data records to the data file after previous data in the file.
Indexes of these data records are automatically setted by reading the data file before.

	$cc->adddatalast($data,$fh,$fhflag);

	my $data = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	]; # hash reference of single data record or array reference of hash references of multiple data records
	my $fh; # file handle (can omit)
	my $fhflag = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and adds data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: 1 , second: (if C<$fhflag> is true) file handle

Fail > first: false (return;)

=cut

sub adddatalast{
	my $self = shift;
	my $datalist = shift;
	my $fh = shift;
	my $fhflag = shift;
	$datalist = [$datalist] if ref $datalist eq 'HASH';
	my $datanum;
	($datanum,$fh) = $self->readdatanum($fh,1);
	return $self->adddata($datalist,$datanum + 1,$fh,$fhflag);
}

=head3 adddata()

This method adds data records to the data file.

	$cc->adddata($datalist,$startindex,$fh,$fhflag);

	my $datalist = {title => "hoge",value => "huga"} || [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	]; # hash reference of single data record or array reference of hash references of multiple data records
	my $startindex = 12; # first index of the data record (can omit if you don't want index numbers)
	my $fh; # file handle (can omit)
	my $fhflag = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and adds data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: 1 , second: (if C<$fhflag> is true) file handle

Fail > first: false (return;)

=cut

sub adddata{
	my $self = shift;
	my $datalist = shift;
	my $startindex = shift;
	my $fh = shift;
	my $fhflag = shift;
	$datalist = [$datalist] if ref $datalist eq 'HASH';
	unless(ref $fh eq 'GLOB'){
		my $encoding = $self->{encoding} ? ':encoding('.$self->{encoding}.')' : '';
		open $fh,'+<'.$encoding,$self->{filename} or open $fh,'>'.$encoding,$self->{filename} or return;
		flock $fh,2;
		seek $fh,0,2;
	}
	$self->{writeorder}->($fh,$datalist,$startindex);
	close $fh unless $fhflag;
	return $fhflag ? (1,$fh) : 1;
}

=head3 writedata()

This method writes data records to the data file.
Before writing data, the contents of the data file will be erased.

	$cc->writedata($datalist,$fh,$fhflag,$noempty);

	my $datalist = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	]; # array reference of hash references of multiple data records
	my $fh; # file handle (can omit)
	my $fhflag = 1; # if true, file handle will not be closed (can omit)
	my $noempty = 1; # see below

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle.
If C<$noempty> is true, the contents of the data file will not be erased, and writes data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: 1 , second: (if C<$fhflag> is true) file handle

Fail > first: false (return;)

=cut

sub writedata{
	my $self = shift;
	my $datalist = shift;
	my $fh = shift;
	my $fhflag = shift;
	my $noempty = shift;
	$datalist = [@{$datalist}]; # escape destructive operation
	splice @$datalist,0,$self->{index};
	unless(ref $fh eq 'GLOB'){
		my $encoding = $self->{encoding} ? ':encoding('.$self->{encoding}.')' : '';
		open $fh,'+<'.$encoding,$self->{filename} or open $fh,'>'.$encoding,$self->{filename} or return;
		flock $fh,2;
	}
	unless($noempty){
		truncate $fh,0;
		seek $fh,0,0;
	}
	return $self->adddata($datalist,$self->{index},$fh,$fhflag);
}

=begin comment

#=head3 writedatarange()

範囲内のデータをファイルに書き出す。

	$cc->writedatarange($datalist,$startindex,$endindex,$fh,$fhflag);

	my $datalist = [
		{title => "hoge",value => "huga"},
		{title => "hoge2",value => "huga"},
		{title => "hoge3",value => "huga"},
	];# 複数データの配列リファレンスのみ許される。
	my $startindex = 2; # 書き出すデータリストの最初のインデックス。0番目のデータから書き出すなら省略可能。
	my $endindex = 10; # 書き出すデータリストの最後のインデックス。最後のデータまで書き出すなら省略可能。
	my $fh; # 省略可能。ファイルハンドル。
	my $fhflag = 1; # 真値を与えればファイルハンドルを維持する。

与えられたファイルハンドルのファイルポインタが先頭でないなら、その位置から書き出します。

成功なら第一返値に1、$fhflagが真なら第二返値にファイルハンドルを返す。失敗なら偽を返す。

=end comment

=cut

=begin comment

sub writedatarange{
	my $self = shift;
	my $datalist = shift;
	my $startindex = shift;
	my $endindex = shift;
	my $fh = shift;
	my $fhflag = shift;
	$datalist = [@{$datalist}]; # escape destructive operation
	if($startindex){
		$startindex = $#$datalist + $startindex + 1 if $startindex < 0;
		if($startindex > $#$datalist){
			warn 'startindex is out of index range';
		}
	}else{
		$startindex = $self->{index};
	}
	splice @$datalist,0,$startindex > $self->{index} ? $startindex : $self->{index};
	if($endindex){
		$endindex = $#$datalist + $endindex + 1 if $endindex < 0;
		if($endindex > $#$datalist){
			warn 'endindex is out of index range';
		}elsif($endindex < $#$datalist){
			splice @$datalist,$endindex + 1;
		}
	}
	return $self->adddata($datalist,$startindex,$fh,$fhflag);
}

=end comment

=cut

=head3 readdata()

This method reads data records from the data file.

	$cc->readdata($fh,$fhflag);

	my $fh; # file handle (can omit)
	my $fhflag = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and reads data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: data list (array reference of hash references) , second: (if C<$fhflag> is true) file handle

Fail > first: false (return;)

=cut

sub readdata{
	my $self = shift;
	my $fh = shift;
	my $data;
	my $fhflag = shift;
	unless(ref $fh eq 'GLOB'){
		$self->{encoding} ? open $fh,"+<:encoding($self->{encoding})",$self->{filename} : open $fh,'+<',$self->{filename} or return;
		flock $fh,2;
		seek $fh,0,0;
	}
	local $/ = $self->{linedelimiter} if $self->{linedelimiter};
	if($self->{delimiter}){
		my $indexcolumn = -1;
		my @key = @{$self->{order}};
		for my $i (0..$#key){
			if($key[$i] eq 1){$indexcolumn = $i;last;}
		}
		my $cnt = $self->{index} - 1;
		while(<$fh>){
			chomp;
			my @column = split /$self->{delimiter}/;
			$indexcolumn >= 0 ? $cnt = $column[$indexcolumn] : $cnt++;
			for my $i (0..$#column){
				$data->[$cnt]->{$key[$i]} = $column[$i] unless $key[$i] eq '1';
			}
		}
	}else{
		my @key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $lineregexpstr = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		my $lineregexp = qr/$lineregexpstr/;
		my $indexcolumn = -1;
		for my $i (0..$#key){
			if($key[$i] eq 1){$indexcolumn = $i;last;}
		}
		my $cnt = $self->{index} - 1;
		while(<$fh>){
			chomp;
			my @column = /$lineregexp/;
			$indexcolumn >= 0 ? $cnt = $column[$indexcolumn] : $cnt++;
			for my $i (0..$#column){
				$data->[$cnt]->{$key[$i]} = $column[$i] unless $key[$i] eq '1';
			}
		}
	}
	close $fh unless $fhflag;
	return $fhflag ? ($data,$fh) : $data;
}

=head3 readdatanum()

This method reads data record's last index number from the data file.

	$cc->readdatanum($fh,$fhflag);

	my $fh; # file handle (can omit)
	my $fhflag = 1; # if true, file handle will not be closed (can omit)

If you give a file handle to the argument, file that defined by constructor is omitted and this method uses given file handle and reads data from the place current file pointer points not from the head of file.

Return value:

Succeed > first: last index , second: (if C<$fhflag> is true) file handle

Fail > first: false (return;)

=cut

sub readdatanum{
	my $self = shift;
	my $fh = shift;
	my $fhflag = shift;
	unless(ref $fh eq 'GLOB'){
		$self->{encoding} ? open $fh,"+<:encoding($self->{encoding})",$self->{filename} : open $fh,'+<',$self->{filename} or return;
		flock $fh,2;
		seek $fh,0,0;
	}
	local $/ = $self->{linedelimiter} if $self->{linedelimiter};
	my $datanum = $self->{index} - 1;
	if($self->{delimiter}){
		my $indexcolumn = -1;
		for my $i (0..$#{$self->{order}}){
			if($self->{order}->[$i] eq 1){$indexcolumn = $i;last;}
		}
		if($indexcolumn < 0){$datanum++ while <$fh>;}
		else{$datanum = (split /$self->{delimiter}/)[$indexcolumn] while <$fh>;}
		chomp $datanum;
	}else{
		my @key = map { $_ % 2 ? $self->{order}->[$_] : () } (0..$#{$self->{order}});
		my @delim = map { $_ % 2 ? () : $self->{order}->[$_] } (0..$#{$self->{order}});
		my $lineregexpstr = '^'.(join '(.*?)',map {quotemeta} @delim) . '(?:' . quotemeta($/) . ')?$';
		my $lineregexp = qr/$lineregexpstr/;
		my $indexcolumn = -1;
		for my $i (0..$#key){
			if($key[$i] eq 1){$indexcolumn = $i;last;}
		}
		if($indexcolumn < 0){$datanum++ while <$fh>;}
		else{$datanum = (/$lineregexp/)[$indexcolumn] while <$fh>;}
	}
	close $fh unless $fhflag;
	return $fhflag ? ($datanum,$fh) : $datanum;
}

=begin comment

#=head3 _setwriteorder()

	$cc->_setwriteorder($order,$delimiter,$linedelimiter);
	$order = [1 title summary];
	$delimiter = "\n";
	$linedelimiter = "\n";

=end comment

=cut

sub _setwriteorder{
	my $order = shift;
	my $delimiter = shift;
	my $linedelimiter = shift;
	if($delimiter){
		return sub{
			my $fh = shift;
			my $datalist = shift;
			my $index = shift;
			local $/ = $linedelimiter if $linedelimiter;
			for my $data (@$datalist){
				print $fh (join $delimiter,map {$_ eq 1 ? $index : defined $data->{$_} ? $data->{$_} : ''} @$order),$/;
				$index ++;
			}
		};
	}else{
		return sub{
			my $fh = shift;
			my $datalist = shift;
			my $index = shift;
			local $/ = $linedelimiter if $linedelimiter;
			for my $data (@$datalist){
				print $fh (map {$_ % 2 ? $order->[$_] eq 1 ? $index : defined $data->{$order->[$_]} ? $data->{$order->[$_]} : '' : $order->[$_]} (0..$#{$order})),$/;
				$index ++;
			}
		};
	}
}

1;

=head1 DEPENDENCIES

This module requires no other modules and libraries.

=head1 NOTES

This module is written in object-oriented style but treating data by naked array or file handle so you should treat data by procedural style.

For example, if you want to delete 3,6 and 8th element in data list completely, the following code will be required.

	splice @$datalist,$_,1 for sort {$b <=> $a} qw(3 6 8);

So, if you want more smart OO, it will be better to use another modules that wraps naked array or file handle in OO (such as Object::Array ... etc?), or create Config::Column::OO etc. which inherits this module and can use methods pop, shift, splice, delete, etc.

=head1 TODO

Odd Engrish

=head1 AUTHOR

Narazaka (http://narazaka.net/)

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2012 by Narazaka, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
