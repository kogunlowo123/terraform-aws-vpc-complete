################################################################################
# VPC Peering Connection
################################################################################

resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = var.accepter_account_id
  peer_region   = var.accepter_region
  auto_accept   = var.auto_accept

  tags = merge(var.tags, {
    Name = var.name
    Side = "requester"
  })
}

resource "aws_vpc_peering_connection_accepter" "this" {
  count = var.auto_accept ? 0 : 1

  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = var.name
    Side = "accepter"
  })
}

################################################################################
# Requester Side Options
################################################################################

resource "aws_vpc_peering_connection_options" "requester" {
  count = var.allow_remote_vpc_dns_resolution ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection.this.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.this]
}

################################################################################
# Routes from Requester to Accepter
################################################################################

resource "aws_route" "requester_to_accepter" {
  count = length(var.requester_route_table_ids)

  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

################################################################################
# Routes from Accepter to Requester
################################################################################

resource "aws_route" "accepter_to_requester" {
  count = var.create_accepter_routes ? length(var.accepter_route_table_ids) : 0

  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
