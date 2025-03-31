import enum
from datetime import datetime

from sqlalchemy import create_engine
from sqlalchemy import func
from sqlalchemy import Enum
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.orm import Mapped
from sqlalchemy.orm import mapped_column
from sqlalchemy.orm import relationship

engine = create_engine("sqlite+pysqlite:///:memory:", echo=True)


class Base(DeclarativeBase):
    pass


class IncidentStatus(enum.Enum):
    ''' Incident object status choices '''
    OPEN = 'Open'
    IN_PROGRESS = 'In progress'
    RESOLVED = 'Resolved'


class IncidentSeverity(enum.Enum):
    ''' Incident object severity choices '''
    CRITICAL = 'Critical'
    HIGH = 'High'
    MEDIUM = 'Medium'
    LOW = 'Low'


class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str]
    creation_date: Mapped[datetime] = mapped_column(
        insert_default=func.now(), default=None)
    status: Mapped[IncidentStatus] = mapped_column(
        Enum(IncidentStatus, create_constraint=True),
        insert_default=IncidentStatus.OPEN
    )
    severity: Mapped[str] = mapped_column(
        Enum(IncidentSeverity, create_contraint=True),
        insert_default=IncidentSeverity.LOW
    )
    assigned_to: Mapped["User"] = relationship(back_populates="User")
    commments: Mapped[list["Comment"]] = relationship(back_populates="Comment",
                                                      cascade="all, delete-orphan")


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    email_address: Mapped[str] = mapped_column(unique=True)
    first_name: Mapped[str]
    last_name: Mapped[str]
    password: Mapped[str]
    assigned_incidents: Mapped[list["Incident"]] = relationship(
        back_populates="Incident")


class Comment(Base):
    __tablename__ = "comments"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    created_by: Mapped[User] = relationship(back_populates="User")
    incident: Mapped[Incident] = relationship(back_populates="Incident")
