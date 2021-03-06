package Net::TDP;

use Moose;

use Net::HTTP::Spore;

has '_spec' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_spec'
);

has '_spore' => (
    is      => 'rw',
    isa     => 'Net::HTTP::Spore::Core',
    lazy    => 1,
    builder => '_build_spore',
);

has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

has 'base_url' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'http://tdp.me/v1'
);

has 'api_key' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
);

{
  no strict 'refs';
  foreach my $write_method ( qw/create_goal completed/) {
    *{$write_method} = sub {
        shift->_spore->$write_method( @_, payload => { @_ } )->body;
    };
  }

  foreach my $read_method ( qw/list_goals list_categories archive_goal/ ) {
    *{$read_method} = sub {
      shift->_spore->$read_method(@_)->body;
    };
  }
}

sub _build_spore {
    my ( $self ) = @_;

    my $client = Net::HTTP::Spore->new_from_string(
        $self->_spec,
        base_url => $self->base_url,
        ( $self->debug ? ( trace => 1 ) : () )
    );

    $client->enable('Format::JSON');
    $client->enable('Auth::Header',
      header_name => 'X-Access-Token',
      header_value => $self->api_key,
    );
    return $client;
}

sub _build_spec {
    return q({
        "base_url"     : "http://tdp.me/v1",
        "api_base_url" : "http://tdp.me/v1",
        "version"      : "v1",
        "name"         : "tdp.me",
        "author"       : [ "J. Shirley <jshirley@tdp.me>" ],
        "meta"         : { "documentation" : "http://tech.tdp.me/clients/perl" },
        "methods"      : {
            "list_categories" : {
                "api_format"      : [ "json" ],
                "path"            : "/category",
                "method"          : "GET",
                "expected_status" : [ 200 ],
                "description"     : "Fetch all categories",
                "authentication"  : true
            },
            "list_goals" : {
                "api_format"      : [ "json" ],
                "path"            : "/goals",
                "method"          : "GET",
                "expected_status" : [ 200 ],
                "description"     : "Fetch all goals",
                "authentication"  : true
            },
            "create_goal" : {
                "api_format"      : [ "json" ],
                "path"            : "/goals",
                "method"          : "POST",
                "expected_status" : [ 201, 400 ],
                "description"     : "Add a new goal",
                "authentication"  : true,
                "requires_params" : [
                  "name", "description", "color",
                  "quantity", "frequency",
                  "category_id"
                ],
                "optional_params": [
                  "quantity_needed", "score", "cooldown",
                  "require_note", "note_prompt",
                  "active", "public", "position"
                ]
            },
            "completed" : {
                "api_format"      : [ "json" ],
                "path"            : "/goals/:id/completion",
                "method"          : "POST",
                "expected_status" : [ 201, 400 ],
                "description"     : "Mark a goal as completed",
                "authentication"  : true,
                "requires_params" : [ "id" ],
                "optional_params" : [ "date", "note", "quantity", "duration" ]
            },
            "archive_goal" : {
                "api_format"      : [ "json" ],
                "path"            : "/goals/:id",
                "method"          : "DELETE",
                "expected_status" : [ 200 ],
                "description"     : "Archive a goal",
                "authentication"  : true,
                "requires_params" : [ "id" ],
                "optional_params" : [ "permanent" ]
            }
        }
    });
}

no Moose;
__PACKAGE__->meta->make_immutable; 1;
