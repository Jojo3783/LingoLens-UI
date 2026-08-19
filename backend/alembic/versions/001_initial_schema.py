"""Initial schema for history and favorites tables

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-08-13 14:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'history',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('input', sa.Text(), nullable=False),
        sa.Column('mode', sa.String(length=20), nullable=False),
        sa.Column('result_json', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(
        'idx_history_created_at',
        'history',
        [sa.text('created_at DESC')],
        unique=False
    )
    op.create_table(
        'favorites',
        sa.Column('history_id', sa.String(length=36), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['history_id'], ['history.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('history_id')
    )


def downgrade() -> None:
    op.drop_table('favorites')
    op.drop_index('idx_history_created_at', table_name='history')
    op.drop_table('history')
