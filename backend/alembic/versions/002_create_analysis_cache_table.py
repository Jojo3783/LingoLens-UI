"""Create analysis_cache table with capacity index

Revision ID: 002_create_analysis_cache_table
Revises: 001_initial_schema
Create Date: 2026-08-15 10:25:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '002_create_analysis_cache_table'
down_revision: Union[str, None] = '001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'analysis_cache',
        sa.Column('key', sa.String(length=255), nullable=False),
        sa.Column('output_json', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('key')
    )
    op.create_index(
        'idx_cache_created_at',
        'analysis_cache',
        [sa.text('created_at ASC')],
        unique=False
    )


def downgrade() -> None:
    op.drop_index('idx_cache_created_at', table_name='analysis_cache')
    op.drop_table('analysis_cache')
